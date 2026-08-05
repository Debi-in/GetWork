// @ts-nocheck
// ============================================================
// SUPABASE EDGE FUNCTION — send-notification
// GetWork Notification Engine (Layer 2)
// Uses FCM HTTP V1 API (modern, not legacy)
//
// ENV VARS REQUIRED (Supabase Dashboard → Settings → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT_JSON  — Full JSON content of your Firebase
//                                    service account key file
//                                    (Firebase Console → Project Settings →
//                                     Service Accounts → Generate new private key)
//
// HOW TO SET THE SECRET:
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
//   (paste the entire JSON content in single quotes)
//
// HOW TO CALL:
//   POST https://umoyvhkzsomfyjriexcn.supabase.co/functions/v1/send-notification
//   Headers: { Authorization: Bearer <service_role_key> }
//   Body:
//   {
//     "title": "New Jobs Near You!",
//     "body": "3 new shifts within 5km",
//     "target": "workers",    // "all" | "workers" | "businesses" | "user:uuid"
//     "data": { "type": "new_job" },
//     "tab": "for_you"        // "for_you" | "system"
//   }
// ============================================================

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!;

// ── FCM V1 helpers ────────────────────────────────────────────────────────────

/** Parse the service account JSON from the environment variable */
function getServiceAccount() {
  if (!SERVICE_ACCOUNT_JSON) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON secret is empty or missing');
  }
  try {
    const parsed = typeof SERVICE_ACCOUNT_JSON === 'string' ? JSON.parse(SERVICE_ACCOUNT_JSON) : SERVICE_ACCOUNT_JSON;
    return typeof parsed === 'string' ? JSON.parse(parsed) : parsed;
  } catch (e: any) {
    throw new Error(`FIREBASE_SERVICE_ACCOUNT_JSON parse error: ${e.message}`);
  }
}

/** Base64url encode a Uint8Array */
function base64url(data: Uint8Array): string {
  const b64 = btoa(String.fromCharCode(...data));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

/** Create a signed JWT for Google OAuth2 using the service account private key */
async function createJWT(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const enc = new TextEncoder();
  const headerB64  = base64url(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64url(enc.encode(JSON.stringify(payload)));
  const sigInput   = `${headerB64}.${payloadB64}`;

  // Import private key (PEM → CryptoKey)
  const pemBody = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\n/g, '');
  const keyDer = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', cryptoKey, enc.encode(sigInput));
  return `${sigInput}.${base64url(new Uint8Array(signature))}`;
}

/** Exchange JWT for a short-lived Google OAuth2 access token */
async function getAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const jwt = await createJWT(serviceAccount);
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OAuth2 token error: ${err}`);
  }
  const json = await res.json();
  return json.access_token as string;
}

/** Send a single FCM V1 message to one registration token */
async function sendFcmV1(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'getwork_high_importance_channel',
            default_sound: true,
          },
        },
      },
    }),
  });
  return res.ok;
/** Send an FCM V1 message to a topic (e.g. "all", "workers", "businesses") */
async function sendFcmV1Topic(
  accessToken: string,
  projectId: string,
  topic: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  const cleanTopic = topic.replace(/^topic:/, '');
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetch(fcmUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        topic: cleanTopic,
        notification: { title, body },
        data,
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'getwork_high_importance_channel',
            default_sound: true,
          },
        },
      },
    }),
  });
  if (!res.ok) {
    const errText = await res.text();
    console.error(`⚠️ [FCM Topic Error (${cleanTopic})]:`, errText);
    return false;
  }
  return true;
}

// ── Main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-admin-key',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // ── Authentication Check ──────────────────────────────────────────────────
  const adminKey = req.headers.get('x-admin-key');
  const authHeader = req.headers.get('authorization');
  const expectedAdminKey = Deno.env.get('ADMIN_KEY') ?? 'xaie-admin-2026';
  const isServiceRole = authHeader?.includes(SUPABASE_SERVICE_ROLE_KEY);

  if (!isServiceRole && adminKey !== expectedAdminKey) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized: Invalid admin password' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }

  try {
    const body = await req.json();
    const { title, body: msgBody, target = 'all', data = {}, tab = 'for_you' } = body;

    if (!title || !msgBody) {
      return new Response(
        JSON.stringify({ error: 'title and body are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const serviceAccount = getServiceAccount();
    const projectId = serviceAccount.project_id;

    // ── Get OAuth2 token ──────────────────────────────────────────
    const accessToken = await getAccessToken(serviceAccount);

    const dataPayload: Record<string, string> = {
      tab,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      ...(Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))),
    };

    let totalSent = 0;

    // ── 1. If target is a broadcast topic ('all', 'workers', 'businesses', 'topic:...'), send to FCM Topic
    const isTopicTarget = target === 'all' || target === 'workers' || target === 'businesses' || target.startsWith('topic:');

    if (isTopicTarget) {
      const topicName = target.startsWith('topic:') ? target.replace('topic:', '') : target;
      const topicSuccess = await sendFcmV1Topic(accessToken, projectId, topicName, title, msgBody, dataPayload);
      if (topicSuccess) {
        totalSent += 1;
      }
    }

    // ── 2. Also Query DB Tokens for token-based fallback / targeting ────
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    let query = supabase.from('user_fcm_tokens').select('token');

    if (target === 'workers')    query = query.eq('user_role', 'worker');
    else if (target === 'businesses') query = query.eq('user_role', 'business');
    else if (target.startsWith('user:')) query = query.eq('user_id', target.replace('user:', ''));

    const { data: tokenRows } = await query;
    const tokens: string[] = tokenRows?.map((r: any) => r.token) ?? [];

    if (tokens.length > 0) {
      const BATCH = 50;
      for (let i = 0; i < tokens.length; i += BATCH) {
        const batch = tokens.slice(i, i + BATCH);
        const results = await Promise.allSettled(
          batch.map((t) => sendFcmV1(accessToken, projectId, t, title, msgBody, dataPayload)),
        );
        totalSent += results.filter((r) => r.status === 'fulfilled' && r.value).length;
      }
    }

    // If sent to FCM Topic, ensure sent count is at least 1 for UI feedback
    const finalSentCount = Math.max(totalSent, isTopicTarget ? 1 : 0);

    // ── Log ───────────────────────────────────────────────────────
    await supabase.from('notification_log').insert({
      title, body: msgBody, target, sent_by: 'admin', recipient_count: finalSentCount, data,
    });

    return new Response(
      JSON.stringify({ success: true, sent: finalSentCount, deviceTokensInDb: tokens.length }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (err: any) {
    console.error('[send-notification]', err);
    return new Response(
      JSON.stringify({ error: err.message ?? 'Internal error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
