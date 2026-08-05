-- ============================================================
-- GETWORK LIVE DATABASE SCHEMA — v2 (matches SupabaseJobsService)
-- Run this in Supabase SQL Editor → New Query → Run
-- This replaces/extends 03_create_jobs_and_applications.sql
-- ============================================================

-- ── 1. PROFILES TABLE ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name     TEXT,
  phone         TEXT,
  role          TEXT DEFAULT 'worker',
  age           INT,
  gender        TEXT,
  experience    TEXT,
  primary_skill TEXT,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Public read profiles') THEN
    CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='profiles' AND policyname='Public insert or update profiles') THEN
    CREATE POLICY "Public insert or update profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 2. JOBS TABLE (column names match SupabaseJobsService) ────
CREATE TABLE IF NOT EXISTS public.jobs (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title              TEXT NOT NULL,
  category           TEXT NOT NULL DEFAULT 'general',       -- matches _parseCategory()
  salary             NUMERIC NOT NULL DEFAULT 700,          -- used by: row['salary']
  salary_type        TEXT NOT NULL DEFAULT 'daily',         -- 'hourly'|'daily'|'fixed'
  address            TEXT NOT NULL DEFAULT 'Kathmandu',     -- row['address']
  latitude           DOUBLE PRECISION DEFAULT 27.7172,
  longitude          DOUBLE PRECISION DEFAULT 85.3240,
  job_start_date     DATE DEFAULT CURRENT_DATE,             -- row['job_start_date']
  shift_start_time   TEXT DEFAULT '09:00 AM',
  shift_end_time     TEXT DEFAULT '05:00 PM',
  status             TEXT NOT NULL DEFAULT 'active',        -- _parseStatus()
  workers_needed     INT DEFAULT 1,
  workers_applied    INT DEFAULT 0,
  is_urgent          BOOLEAN DEFAULT false,
  business_id        UUID,
  business_name      TEXT DEFAULT 'GetWork Partner',
  business_logo_url  TEXT,
  description        TEXT DEFAULT '',
  requirements_text  TEXT[] DEFAULT '{}',
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='jobs' AND policyname='Public read jobs') THEN
    CREATE POLICY "Public read jobs" ON public.jobs FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='jobs' AND policyname='Public insert or update jobs') THEN
    CREATE POLICY "Public insert or update jobs" ON public.jobs FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;

-- ── 3. SEED JOBS (Kathmandu, Lalitpur, Bhaktapur) ────────────
INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Supermarket Cashier', 'retail', 700, 'daily', 'Patan Dhoka, Lalitpur', 27.6766, 85.3184, CURRENT_DATE, '10:00 AM', '06:00 PM', 'active', 2, 2, false, 'Himalayan Mart', 'Handle cash & card payments at the supermarket counter.', ARRAY['Basic math skills', 'Friendly attitude', 'No experience required']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Supermarket Cashier');

INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Delivery Rider', 'delivery', 900, 'daily', 'Thamel, Kathmandu', 27.7152, 85.3123, CURRENT_DATE, '09:00 AM', '05:00 PM', 'active', 3, 1, true, 'Quick Express', 'Deliver parcels across Kathmandu on your bike.', ARRAY['Own motorcycle', 'Valid driving license', 'Android phone']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Delivery Rider');

INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Event Setup Staff', 'events', 1300, 'daily', 'Durbar Square, Bhaktapur', 27.6710, 85.4298, CURRENT_DATE + 1, '07:00 AM', '05:00 PM', 'active', 10, 4, false, 'Royal Events', 'Help set up stages, tents, and audio equipment for a cultural event.', ARRAY['Physical fitness', 'Team player', 'Minimum 16 years old']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Event Setup Staff');

INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Kitchen Helper', 'food', 800, 'daily', 'New Baneshwor, Kathmandu', 27.6858, 85.3431, CURRENT_DATE, '10:00 AM', '04:00 PM', 'active', 2, 0, false, 'Spice Garden Restaurant', 'Assist in kitchen prep, chopping vegetables, and cleaning.', ARRAY['Basic kitchen knowledge', 'Clean & punctual']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Kitchen Helper');

INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Building Cleaner', 'cleaning', 600, 'daily', 'Pulchowk, Lalitpur', 27.6780, 85.3188, CURRENT_DATE, '08:00 AM', '12:00 PM', 'active', 1, 0, false, 'Clean Pro Services', 'Clean office floors, windows, and restrooms in a corporate building.', ARRAY['Own cleaning supplies (bonus)', 'Honest & reliable']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Building Cleaner');

INSERT INTO public.jobs (title, category, salary, salary_type, address, latitude, longitude, job_start_date, shift_start_time, shift_end_time, status, workers_needed, workers_applied, is_urgent, business_name, description, requirements_text)
SELECT 'Tech Support Intern', 'tech', 1500, 'daily', 'Naxal, Kathmandu', 27.7192, 85.3229, CURRENT_DATE + 2, '10:00 AM', '05:00 PM', 'active', 1, 0, false, 'NexGen IT', 'Help clients with basic computer troubleshooting and setup.', ARRAY['Basic IT knowledge', 'Good communication', 'Own laptop preferred']
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Tech Support Intern');

-- ── 4. JOB APPLICATIONS TABLE ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.job_applications (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id         UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_id      UUID,
  worker_name    TEXT NOT NULL,
  worker_phone   TEXT NOT NULL,
  cover_note     TEXT,
  status         TEXT NOT NULL DEFAULT 'pending',   -- 'pending'|'accepted'|'rejected'
  applied_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
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

-- ── 5. ATOMIC INCREMENT RPC (used by applyForJob) ─────────────
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
