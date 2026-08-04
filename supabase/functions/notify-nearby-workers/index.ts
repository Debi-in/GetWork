// ============================================================
// SUPABASE EDGE FUNCTION — notify-nearby-workers
// GetWork Notification Engine — Auto Trigger (Layer 2)
//
// TRIGGER: Supabase DB Webhook fires this when a new job is
//          inserted into the `jobs` table.
//
// HOW TO SET UP THE WEBHOOK:
//   Supabase Dashboard → Database → Webhooks → Create a new hook
//   Name:    "notify_nearby_workers"
//   Table:   jobs
//   Events:  INSERT
//   URL:     https://<project>.supabase.co/functions/v1/notify-nearby-workers
//   HTTP Headers:
//     Authorization: Bearer <service_role_key>
//
// ENV VARS REQUIRED:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_SERVER_KEY
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;
const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

const NEARBY_RADIUS_KM = 5; // Notify workers within 5km

Deno.serve(async (req) => {
  try {
    const payload = await req.json();

    // Supabase DB webhooks send { type, table, record, old_record, schema }
    const job = payload.record;
    if (!job) {
      return new Response(JSON.stringify({ skip: true, reason: 'no record' }), { status: 200 });
    }

    const { id: jobId, title: jobTitle, latitude, longitude, category, salary_amount, salary_type } = job;

    if (!latitude || !longitude) {
      return new Response(JSON.stringify({ skip: true, reason: 'no location' }), { status: 200 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Find workers within 5km using PostGIS ────────────────────
    // Haversine approximation: 1 degree ≈ 111km
    // For 5km radius: delta = 5 / 111 = ~0.045 degrees
    const delta = NEARBY_RADIUS_KM / 111;

    // Get FCM tokens of workers within the bounding box
    // (Full PostGIS ST_DWithin would be ideal if PostGIS extension is enabled)
    const { data: nearbyWorkers, error } = await supabase
      .from('profiles')
      .select(`
        id,
        user_fcm_tokens!inner(token)
      `)
      .eq('user_type', 'worker')
      .gte('latitude', latitude - delta)
      .lte('latitude', latitude + delta)
      .gte('longitude', longitude - delta)
      .lte('longitude', longitude + delta);

    if (error) {
      console.error('[notify-nearby-workers] DB Error:', error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    // Extract all FCM tokens
    const tokens: string[] = [];
    for (const worker of (nearbyWorkers ?? [])) {
      const workerTokens = (worker as any).user_fcm_tokens;
      if (Array.isArray(workerTokens)) {
        tokens.push(...workerTokens.map((t: any) => t.token));
      } else if (workerTokens?.token) {
        tokens.push(workerTokens.token);
      }
    }

    if (tokens.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0, reason: 'no nearby workers' }), { status: 200 });
    }

    // ── Build notification message ────────────────────────────────
    const salaryStr = salary_amount
      ? `• Rs. ${salary_amount}/${salary_type ?? 'day'}`
      : '';
    const notifTitle = 'New Job Near You! 📍';
    const notifBody = `${jobTitle ?? 'A new shift'} is available within ${NEARBY_RADIUS_KM}km ${salaryStr}`.trim();

    // ── Send via FCM in batches of 500 ───────────────────────────
    let totalSent = 0;
    const BATCH_SIZE = 500;
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const fcmRes = await fetch(FCM_URL, {
        method: 'POST',
        headers: {
          Authorization: `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          registration_ids: batch,
          notification: { title: notifTitle, body: notifBody },
          data: {
            type: 'new_job',
            jobId: String(jobId),
            tab: 'for_you',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        }),
      });
      if (fcmRes.ok) totalSent += batch.length;
    }

    // ── Log to notification_log ───────────────────────────────────
    await supabase.from('notification_log').insert({
      title: notifTitle,
      body: notifBody,
      target: `nearby_workers_${NEARBY_RADIUS_KM}km`,
      sent_by: 'system',
      recipient_count: totalSent,
      data: { jobId, type: 'new_job' },
    });

    console.log(`[notify-nearby-workers] Job ${jobId} → notified ${totalSent} workers`);
    return new Response(JSON.stringify({ success: true, sent: totalSent }), { status: 200 });

  } catch (err: any) {
    console.error('[notify-nearby-workers] Unhandled error:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
