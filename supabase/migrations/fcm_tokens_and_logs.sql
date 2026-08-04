-- ============================================================
-- FCM TOKEN STORAGE — GetWork App
-- Run this in Supabase SQL Editor → New Query → Run
-- ============================================================

-- 1. FCM Tokens table (one row per device per user)
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token        TEXT NOT NULL UNIQUE,
  platform     TEXT NOT NULL DEFAULT 'android', -- 'android' | 'ios' | 'web'
  user_role    TEXT NOT NULL DEFAULT 'worker',   -- 'worker' | 'business'
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast token lookups by user
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_role    ON public.user_fcm_tokens(user_role);

-- Row Level Security
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Users can only read/write their own token
CREATE POLICY "Users manage own FCM tokens"
  ON public.user_fcm_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Service role (Edge Functions) can read ALL tokens for sending notifications
-- (uses service_role key, bypasses RLS automatically)


-- 2. Notification Log table (records every sent notification for history)
CREATE TABLE IF NOT EXISTS public.notification_log (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  target       TEXT NOT NULL,   -- 'all' | 'workers' | 'businesses' | 'user:{id}'
  sent_by      TEXT NOT NULL DEFAULT 'system',  -- 'system' | 'admin'
  recipient_count INT DEFAULT 0,
  data         JSONB,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Only admins / service role can write notification logs
ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read notification log"
  ON public.notification_log
  FOR SELECT
  USING (true);

CREATE POLICY "Only service role can insert"
  ON public.notification_log
  FOR INSERT
  WITH CHECK (false); -- blocked for anon; service_role bypasses RLS
