-- ============================================================
-- GETWORK REAL DATABASE SCHEMA — Jobs, Applications, Profiles
-- Run this in Supabase SQL Editor → New Query → Run
-- ============================================================

-- 1. PROFILES TABLE
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
CREATE POLICY "Public read profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Public insert or update profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

-- 2. JOBS TABLE
CREATE TABLE IF NOT EXISTS public.jobs (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title         TEXT NOT NULL,
  category      TEXT NOT NULL DEFAULT 'General',
  pay_rate      NUMERIC NOT NULL,
  pay_type      TEXT NOT NULL DEFAULT 'day',
  location_name TEXT NOT NULL,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  shift_date    TEXT,
  status        TEXT NOT NULL DEFAULT 'Active',
  workers_needed INT DEFAULT 1,
  workers_hired  INT DEFAULT 0,
  business_name TEXT DEFAULT 'GetWork Partner',
  business_id   UUID,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read jobs" ON public.jobs FOR SELECT USING (true);
CREATE POLICY "Public insert or update jobs" ON public.jobs FOR ALL USING (true) WITH CHECK (true);

-- Seed initial Kathmandu / Lalitpur / Bhaktapur jobs if table is empty
INSERT INTO public.jobs (title, category, pay_rate, pay_type, location_name, latitude, longitude, shift_date, status, workers_needed, workers_hired, business_name)
SELECT 'Supermarket Cashier', 'Retail & Sales', 700, 'day', 'Patan Dhoka, Lalitpur', 27.6766, 85.3184, 'Today, 10:00 AM - 06:00 PM', 'Active', 2, 2, 'Himalayan Mart'
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Supermarket Cashier');

INSERT INTO public.jobs (title, category, pay_rate, pay_type, location_name, latitude, longitude, shift_date, status, workers_needed, workers_hired, business_name)
SELECT 'Delivery Rider', 'Delivery & Courier', 900, 'day', 'Thamel, Kathmandu', 27.7152, 85.3123, 'Today, 09:00 AM - 05:00 PM', 'Active', 3, 1, 'Quick Express'
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Delivery Rider');

INSERT INTO public.jobs (title, category, pay_rate, pay_type, location_name, latitude, longitude, shift_date, status, workers_needed, workers_hired, business_name)
SELECT 'Event Setup Staff', 'Events & Promotion', 1300, 'day', 'Durbar Square, Bhaktapur', 27.6710, 85.4298, 'Tomorrow, 07:00 AM - 05:00 PM', 'Active', 10, 4, 'Royal Events'
WHERE NOT EXISTS (SELECT 1 FROM public.jobs WHERE title = 'Event Setup Staff');

-- 3. JOB APPLICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.job_applications (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id       UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
  worker_name  TEXT NOT NULL,
  worker_phone TEXT NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending',
  applied_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read job_applications" ON public.job_applications FOR SELECT USING (true);
CREATE POLICY "Public insert job_applications" ON public.job_applications FOR INSERT WITH CHECK (true);
