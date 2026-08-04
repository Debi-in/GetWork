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
  try {
    return JSON.parse(SERVICE_ACCOUNT_JSON);
  } catch {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is missing or invalid JSON');
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
}

// ── Main handler ──────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
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
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const serviceAccount = getServiceAccount();
    const projectId = serviceAccount.project_id;

    // ── Fetch FCM Tokens ──────────────────────────────────────────
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    let query = supabase.from('user_fcm_tokens').select('token');

    if (target === 'workers')    query = query.eq('user_role', 'worker');
    else if (target === 'businesses') query = query.eq('user_role', 'business');
    else if (target.startsWith('user:')) query = query.eq('user_id', target.replace('user:', ''));
    // 'all' → no filter

    const { data: tokenRows, error: tokenErr } = await query;
    if (tokenErr) throw tokenErr;

    const tokens: string[] = tokenRows?.map((r: any) => r.token) ?? [];
    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, sent: 0, message: 'No tokens for target' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Get OAuth2 token (one call, reuse for all messages) ───────
    const accessToken = await getAccessToken(serviceAccount);

    // ── Send FCM V1 messages ──────────────────────────────────────
    const dataPayload: Record<string, string> = {
      tab,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      ...(Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))),
    };

    // Send concurrently in batches of 50
    let totalSent = 0;
    const BATCH = 50;
    for (let i = 0; i < tokens.length; i += BATCH) {
      const batch = tokens.slice(i, i + BATCH);
      const results = await Promise.allSettled(
        batch.map((t) => sendFcmV1(accessToken, projectId, t, title, msgBody, dataPayload)),
      );
      totalSent += results.filter((r) => r.status === 'fulfilled' && r.value).length;
    }

    // ── Log ───────────────────────────────────────────────────────
    await supabase.from('notification_log').insert({
      title, body: msgBody, target, sent_by: 'admin', recipient_count: totalSent, data,
    });

    return new Response(
      JSON.stringify({ success: true, sent: totalSent }),
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
