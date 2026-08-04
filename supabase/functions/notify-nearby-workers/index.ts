// @ts-nocheck
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
const SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!;

const NEARBY_RADIUS_KM = 5;

function getServiceAccount() {
  if (!SERVICE_ACCOUNT_JSON) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is missing');
  const parsed = typeof SERVICE_ACCOUNT_JSON === 'string' ? JSON.parse(SERVICE_ACCOUNT_JSON) : SERVICE_ACCOUNT_JSON;
  return typeof parsed === 'string' ? JSON.parse(parsed) : parsed;
}

function base64url(data: Uint8Array): string {
  const b64 = btoa(String.fromCharCode(...data));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

async function getAccessToken(sa: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now, exp: now + 3600,
  };
  const enc = new TextEncoder();
  const h = base64url(enc.encode(JSON.stringify(header)));
  const p = base64url(enc.encode(JSON.stringify(payload)));
  const pemBody = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----/g, '').replace(/\n/g, '');
  const keyDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', keyDer, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, enc.encode(`${h}.${p}`));
  const jwt = `${h}.${p}.${base64url(new Uint8Array(sig))}`;
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
  });
  return (await res.json()).access_token;
}

async function sendOne(accessToken: string, projectId: string, token: string, title: string, body: string, data: Record<string, string>) {
  await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: { priority: 'HIGH', notification: { channel_id: 'getwork_high_importance_channel' } },
      },
    }),
  });
}

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

    // ── Send via FCM V1 ───────────────────────────────────────────
    const sa = getServiceAccount();
    const accessToken = await getAccessToken(sa);
    const dataPayload = { type: 'new_job', jobId: String(jobId), tab: 'for_you', click_action: 'FLUTTER_NOTIFICATION_CLICK' };

    await Promise.allSettled(tokens.map((t) => sendOne(accessToken, sa.project_id, t, notifTitle, notifBody, dataPayload)));
    const totalSent = tokens.length;

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
