// ============================================================
// SUPABASE EDGE FUNCTION — send-notification
// GetWork Notification Engine (Layer 2)
//
// HOW TO DEPLOY:
//   supabase functions deploy send-notification
//
// ENV VARS REQUIRED (set in Supabase Dashboard → Settings → Edge Functions):
//   FCM_SERVER_KEY     — Firebase Cloud Messaging Server Key
//                        Firebase Console → Project Settings → Cloud Messaging
//                        → Cloud Messaging API (Legacy) → Server Key
//
// HOW TO CALL (from admin panel or another Edge Function):
//   POST https://<project>.supabase.co/functions/v1/send-notification
//   Headers: { Authorization: Bearer <service_role_key> }
//   Body:
//   {
//     "title": "New Jobs Found!",
//     "body": "3 new shifts within 5km of you",
//     "target": "workers",           // "all" | "workers" | "businesses" | "user:uuid"
//     "data": { "type": "new_job" }, // optional deep-link payload
//     "tab": "for_you"               // "for_you" (default) | "system"
//   }
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;

const FCM_URL = 'https://fcm.googleapis.com/fcm/send';

Deno.serve(async (req) => {
  // CORS Headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { title, body: msgBody, target = 'all', data = {}, tab = 'for_you' } = body;

    if (!title || !msgBody) {
      return new Response(
        JSON.stringify({ error: 'title and body are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase admin client (service role — bypasses RLS)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Fetch FCM Tokens based on target ─────────────────────────
    let query = supabase.from('user_fcm_tokens').select('token');

    if (target === 'workers') {
      query = query.eq('user_role', 'worker');
    } else if (target === 'businesses') {
      query = query.eq('user_role', 'business');
    } else if (target.startsWith('user:')) {
      const userId = target.replace('user:', '');
      query = query.eq('user_id', userId);
    }
    // target === 'all' → no filter, fetch everything

    const { data: tokenRows, error: tokenErr } = await query;
    if (tokenErr) throw tokenErr;

    const tokens: string[] = tokenRows?.map((r: any) => r.token) ?? [];

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, sent: 0, message: 'No tokens found for target' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // ── FCM Multicast Send (up to 500 tokens per batch) ──────────
    const notificationPayload = {
      notification: { title, body: msgBody },
      data: {
        ...data,
        tab,               // 'for_you' or 'system' — the Flutter app reads this
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    let totalSent = 0;
    const BATCH_SIZE = 500;

    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const fcmBody = {
        ...notificationPayload,
        registration_ids: batch,
      };

      const fcmRes = await fetch(FCM_URL, {
        method: 'POST',
        headers: {
          Authorization: `key=${FCM_SERVER_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmBody),
      });

      if (fcmRes.ok) {
        totalSent += batch.length;
      }
    }

    // ── Log this notification to notification_log ─────────────────
    await supabase.from('notification_log').insert({
      title,
      body: msgBody,
      target,
      sent_by: 'admin',
      recipient_count: totalSent,
      data,
    });

    return new Response(
      JSON.stringify({ success: true, sent: totalSent }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (err: any) {
    console.error('[send-notification] Error:', err);
    return new Response(
      JSON.stringify({ error: err.message ?? 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
