-- ============================================================
-- MIGRATION 05: Conversations & Messages (Real-time Chat)
-- Run this in Supabase SQL Editor → New Query → Run All
-- ============================================================

-- Enable UUID extension (already enabled but safe to repeat)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── conversations table ──────────────────────────────────────
-- One row per worker↔business pair for a job
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
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='conversations' AND policyname='Public read conversations'
  ) THEN
    CREATE POLICY "Public read conversations"
      ON public.conversations FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='conversations' AND policyname='Public insert conversations'
  ) THEN
    CREATE POLICY "Public insert conversations"
      ON public.conversations FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='conversations' AND policyname='Public update conversations'
  ) THEN
    CREATE POLICY "Public update conversations"
      ON public.conversations FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── messages table ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_type     TEXT NOT NULL DEFAULT 'system',   -- 'system' | 'business' | 'worker'
  sender_name     TEXT NOT NULL DEFAULT 'GetWork',
  body            TEXT NOT NULL DEFAULT '',
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='messages' AND policyname='Public read messages'
  ) THEN
    CREATE POLICY "Public read messages"
      ON public.messages FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='messages' AND policyname='Public insert messages'
  ) THEN
    CREATE POLICY "Public insert messages"
      ON public.messages FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='messages' AND policyname='Public update messages'
  ) THEN
    CREATE POLICY "Public update messages"
      ON public.messages FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── Realtime: enable for live updates ───────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- ── Seed: system "Welcome" message for any existing conversations ──
-- This ensures every new business always sees at least one message
-- (You can re-run safely — DO NOTHING on conflict)
INSERT INTO public.conversations (
  id, business_name, worker_name, worker_phone,
  last_message, last_message_at, unread_count
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'GetWork',
  'GetWork System',
  '+977-0000000000',
  '👋 Welcome to GetWork! Post your first job to start receiving applications.',
  NOW(),
  1
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.messages (
  conversation_id, sender_type, sender_name, body, created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'system',
  'GetWork',
  '👋 Welcome to GetWork Business! Here you''ll see messages from workers who apply to your jobs. Post your first shift to get started — workers in your area will apply within minutes.',
  NOW()
)
ON CONFLICT DO NOTHING;
