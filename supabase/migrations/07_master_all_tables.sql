-- ============================================================
-- 🚀 MIGRATION 07: MASTER ALL TABLES & COLUMNS CHECK (GetWork App)
-- Run this in Supabase SQL Editor to guarantee 100% table & column readiness
-- Safe to run multiple times (idempotent with IF NOT EXISTS checks)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── 1. PROFILES TABLE ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name        TEXT,
  phone            TEXT,
  role             TEXT DEFAULT 'worker',
  user_type        TEXT DEFAULT 'worker',
  address          TEXT,
  age              INT,
  gender           TEXT,
  experience       TEXT,
  experience_level TEXT,
  primary_skill    TEXT,
  avatar_url       TEXT,
  updated_at       TIMESTAMPTZ DEFAULT NOW(),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure all columns exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS user_type TEXT DEFAULT 'worker';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS experience_level TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Public read profiles') THEN
    CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Public insert or update profiles') THEN
    CREATE POLICY "Public insert or update profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 2. JOBS TABLE ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.jobs (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title              TEXT NOT NULL,
  category           TEXT NOT NULL DEFAULT 'general',
  salary             NUMERIC NOT NULL DEFAULT 700,
  salary_type        TEXT NOT NULL DEFAULT 'daily',
  address            TEXT NOT NULL DEFAULT 'Kathmandu',
  latitude           DOUBLE PRECISION DEFAULT 27.7172,
  longitude          DOUBLE PRECISION DEFAULT 85.3240,
  job_start_date     DATE DEFAULT CURRENT_DATE,
  shift_start_time   TEXT DEFAULT '09:00 AM',
  shift_end_time     TEXT DEFAULT '05:00 PM',
  status             TEXT NOT NULL DEFAULT 'active',
  workers_needed     INT DEFAULT 1,
  workers_applied    INT DEFAULT 0,
  is_urgent          BOOLEAN DEFAULT false,
  business_id        UUID,
  business_name      TEXT DEFAULT 'GetWork Partner',
  business_logo_url  TEXT,
  description        TEXT DEFAULT '',
  requirements_text  TEXT[] DEFAULT '{}',
  type               TEXT DEFAULT 'scheduled',
  job_status_v2      TEXT DEFAULT 'open',
  expires_at         TIMESTAMPTZ,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure columns exist
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'scheduled';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS job_status_v2 TEXT DEFAULT 'open';
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='jobs' AND policyname='Public read jobs') THEN
    CREATE POLICY "Public read jobs" ON public.jobs FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='jobs' AND policyname='Public insert or update jobs') THEN
    CREATE POLICY "Public insert or update jobs" ON public.jobs FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 3. JOB APPLICATIONS TABLE ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.job_applications (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id         UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_id      UUID,
  worker_name    TEXT NOT NULL,
  worker_phone   TEXT NOT NULL,
  cover_note     TEXT,
  status         TEXT NOT NULL DEFAULT 'pending',
  applied_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='job_applications' AND policyname='Public read job_applications') THEN
    CREATE POLICY "Public read job_applications" ON public.job_applications FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='job_applications' AND policyname='Public insert job_applications') THEN
    CREATE POLICY "Public insert job_applications" ON public.job_applications FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='job_applications' AND policyname='Public update job_applications') THEN
    CREATE POLICY "Public update job_applications" ON public.job_applications FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 4. CONVERSATIONS TABLE ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.conversations (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id          UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  business_name   TEXT NOT NULL DEFAULT '',
  worker_name     TEXT NOT NULL DEFAULT '',
  worker_phone    TEXT NOT NULL DEFAULT '',
  last_message    TEXT NOT NULL DEFAULT '',
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  unread_count    INT NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='Public read conversations') THEN
    CREATE POLICY "Public read conversations" ON public.conversations FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='Public insert conversations') THEN
    CREATE POLICY "Public insert conversations" ON public.conversations FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='conversations' AND policyname='Public update conversations') THEN
    CREATE POLICY "Public update conversations" ON public.conversations FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 5. MESSAGES TABLE ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_type     TEXT NOT NULL DEFAULT 'system',
  sender_name     TEXT NOT NULL DEFAULT 'GetWork',
  body            TEXT NOT NULL DEFAULT '',
  content         TEXT DEFAULT '',
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS body TEXT NOT NULL DEFAULT '';
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS content TEXT DEFAULT '';

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='Public read messages') THEN
    CREATE POLICY "Public read messages" ON public.messages FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='Public insert messages') THEN
    CREATE POLICY "Public insert messages" ON public.messages FOR INSERT WITH CHECK (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='messages' AND policyname='Public update messages') THEN
    CREATE POLICY "Public update messages" ON public.messages FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 6. NOTIFICATIONS TABLE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       VARCHAR(255) NOT NULL,
  body        TEXT NOT NULL,
  type        VARCHAR(50) NOT NULL DEFAULT 'general',
  is_read     BOOLEAN DEFAULT FALSE,
  data        JSONB DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='notifications' AND policyname='Public manage notifications') THEN
    CREATE POLICY "Public manage notifications" ON public.notifications FOR ALL USING (true);
  END IF;
END $$;

-- ── 7. FCM DEVICE TOKENS TABLE ────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fcm_device_tokens (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_token  TEXT NOT NULL UNIQUE,
  device_os     TEXT,
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.fcm_device_tokens ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='fcm_device_tokens' AND policyname='Public manage fcm_device_tokens') THEN
    CREATE POLICY "Public manage fcm_device_tokens" ON public.fcm_device_tokens FOR ALL USING (true);
  END IF;
END $$;

-- ── 8. ATOMIC INCREMENT RPC ───────────────────────────────────
CREATE OR REPLACE FUNCTION increment_workers_applied(job_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.jobs
  SET workers_applied = COALESCE(workers_applied, 0) + 1
  WHERE id = job_id;
END;
$$;

-- ── 9. REALTIME SUBSCRIPTIONS ──────────────────────────────────
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ── 10. VERIFY ALL TABLES ──────────────────────────────────────
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
