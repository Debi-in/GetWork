// ============================================================
// SUPABASE EDGE FUNCTION — notify-application-status
// GetWork Notification Engine — Auto Trigger (Layer 2)
//
// TRIGGER: Supabase DB Webhook fires this when an application
//          row in `applications` table is UPDATED.
//
// HOW TO SET UP THE WEBHOOK:
//   Supabase Dashboard → Database → Webhooks → Create a new hook
//   Name:    "notify_application_status"
//   Table:   applications
//   Events:  UPDATE
//   URL:     https://<project>.supabase.co/functions/v1/notify-application-status
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

Deno.serve(async (req) => {
  try {
    const payload = await req.json();

    const newRecord = payload.record;     // current row values
    const oldRecord = payload.old_record; // previous row values

    if (!newRecord || !oldRecord) {
      return new Response(JSON.stringify({ skip: true }), { status: 200 });
    }

    // Only fire if status actually changed
    if (newRecord.status === oldRecord.status) {
      return new Response(JSON.stringify({ skip: true, reason: 'status unchanged' }), { status: 200 });
    }

    const { status, worker_id, job_id } = newRecord;

    // Only handle meaningful status changes
    const notifiableStatuses = ['accepted', 'rejected', 'completed'];
    if (!notifiableStatuses.includes(status)) {
      return new Response(JSON.stringify({ skip: true, reason: 'status not notifiable' }), { status: 200 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Get job title ─────────────────────────────────────────────
    const { data: jobData } = await supabase
      .from('jobs')
      .select('title, business_name')
      .eq('id', job_id)
      .single();

    const jobTitle = jobData?.title ?? 'your job application';
    const businessName = jobData?.business_name ?? 'The employer';

    // ── Get worker's FCM token ────────────────────────────────────
    const { data: tokenRows } = await supabase
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', worker_id);

    const tokens: string[] = tokenRows?.map((r: any) => r.token) ?? [];
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ skip: true, reason: 'no tokens' }), { status: 200 });
    }

    // ── Build message based on status ────────────────────────────
    let title = '';
    let body = '';

    if (status === 'accepted') {
      title = 'Application Accepted! 🎉';
      body = `${businessName} accepted your application for "${jobTitle}". Tap to view details.`;
    } else if (status === 'rejected') {
      title = 'Application Update';
      body = `Your application for "${jobTitle}" was not selected. Keep applying — more jobs await!`;
    } else if (status === 'completed') {
      title = 'Shift Completed ✅';
      body = `Your shift at "${jobTitle}" is marked complete. Rate your experience.`;
    }

    // ── Send FCM notification ─────────────────────────────────────
    const fcmRes = await fetch(FCM_URL, {
      method: 'POST',
      headers: {
        Authorization: `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        registration_ids: tokens,
        notification: { title, body },
        data: {
          type: 'application_status',
          jobId: String(job_id),
          status,
          tab: 'for_you',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      }),
    });

    // ── Log it ────────────────────────────────────────────────────
    await supabase.from('notification_log').insert({
      title,
      body,
      target: `user:${worker_id}`,
      sent_by: 'system',
      recipient_count: tokens.length,
      data: { jobId: job_id, status },
    });

    console.log(`[notify-application-status] ${status} → worker ${worker_id} → ${tokens.length} tokens`);
    return new Response(JSON.stringify({ success: true, status, sent: tokens.length }), { status: 200 });

  } catch (err: any) {
    console.error('[notify-application-status] Error:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
