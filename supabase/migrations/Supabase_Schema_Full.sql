-- ============================================================
-- GETWORK APP — JOBS TABLE PATCH + FILTER FUNCTION FIX
-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/umoyvhkzsomfyjriexcn/sql/new
-- ============================================================
-- The existing jobs table uses daily_rate / hourly_rate columns.
-- This patch adds a unified `salary` column and fixes the filter.
-- ============================================================

-- STEP 1: Add unified `salary` column (safe, only if not already there)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS salary         NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS workers_applied INT           DEFAULT 0;

-- STEP 2: Populate `salary` from existing rate columns
UPDATE public.jobs SET salary =
  CASE salary_type::TEXT
    WHEN 'hourly'   THEN COALESCE(hourly_rate, 0)
    WHEN 'daily'    THEN COALESCE(daily_rate, 0)
    WHEN 'weekly'   THEN COALESCE(weekly_rate, 0)
    WHEN 'monthly'  THEN COALESCE(monthly_rate, 0)
    WHEN 'project'  THEN COALESCE(total_project_salary, 0)
    ELSE COALESCE(daily_rate, hourly_rate, 0)
  END
WHERE salary IS NULL OR salary = 0;

-- STEP 3: Add indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_jobs_salary          ON public.jobs (salary);
CREATE INDEX IF NOT EXISTS idx_jobs_salary_type_txt ON public.jobs (salary_type);

-- STEP 4: Re-create the filter function (using the real schema)
DROP FUNCTION IF EXISTS filter_jobs;

CREATE OR REPLACE FUNCTION filter_jobs(
  p_category     TEXT    DEFAULT NULL,
  p_salary_type  TEXT    DEFAULT NULL,
  p_min_salary   NUMERIC DEFAULT 0,
  p_max_salary   NUMERIC DEFAULT 100000,
  p_is_urgent    BOOLEAN DEFAULT FALSE,
  p_search_query TEXT    DEFAULT NULL
)
RETURNS SETOF public.jobs
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.jobs
  WHERE status = 'active'
    AND (p_category IS NULL OR p_category = 'all'
         OR category::TEXT = p_category)
    AND (p_salary_type IS NULL
         OR salary_type::TEXT = p_salary_type)
    AND (salary >= p_min_salary AND salary <= p_max_salary)
    AND (NOT p_is_urgent OR is_urgent = TRUE)
    AND (
      p_search_query IS NULL OR p_search_query = '' OR
      title         ILIKE '%' || p_search_query || '%' OR
      business_name ILIKE '%' || p_search_query || '%' OR
      address       ILIKE '%' || p_search_query || '%'
    )
  ORDER BY created_at DESC;
$$;

-- STEP 5: Add more seed jobs (Kathmandu area) using the real column names
-- (Safe: ON CONFLICT DO NOTHING skips if already exists)
INSERT INTO public.jobs (
  id, title, business_name,
  latitude, longitude, address, landmark,
  category, description,
  salary_type, daily_rate, hourly_rate, salary,
  job_start_date, shift_start_time, shift_end_time,
  workers_needed, workers_applied,
  is_urgent, is_featured, status,
  allow_whatsapp, whatsapp_number
) VALUES
(
  '55555555-5555-5555-5555-555555555555',
  'Retail Sales Staff', 'CG Electronics',
  27.7050, 85.3143, 'Durbar Marg, Kathmandu', 'CG Mall',
  'retail', 'Sales associate for electronics showroom.',
  'daily', 600.00, 75.00, 600.00,
  CURRENT_DATE, '10:00 AM', '07:00 PM',
  2, 0, FALSE, FALSE, 'active', FALSE, NULL
),
(
  '66666666-6666-6666-6666-666666666666',
  'Office Cleaning Staff', 'CleanPro Services',
  27.7100, 85.3200, 'Lazimpat, Kathmandu', 'Near French Embassy',
  'cleaning', 'Morning cleaning shift for corporate office.',
  'daily', 450.00, 56.25, 450.00,
  CURRENT_DATE, '06:00 AM', '10:00 AM',
  2, 0, FALSE, FALSE, 'active', FALSE, NULL
),
(
  '77777777-7777-7777-7777-777777777777',
  'IT Support Technician', 'TechNova Nepal',
  27.7188, 85.3175, 'Thamel, Kathmandu', 'Thamel Chowk',
  'tech', 'On-site IT support for hardware & software.',
  'daily', 1200.00, 150.00, 1200.00,
  CURRENT_DATE, '09:00 AM', '05:00 PM',
  1, 0, FALSE, FALSE, 'active', TRUE, '+9779801234567'
),
(
  '88888888-8888-8888-8888-888888888888',
  'Construction Labourer', 'Shrestha Builders',
  27.7251, 85.3500, 'Bhaktapur Road, Bhaktapur', 'Suryabinayak',
  'construction', 'General labour for building project.',
  'daily', 900.00, 112.50, 900.00,
  CURRENT_DATE, '07:00 AM', '04:00 PM',
  6, 3, TRUE, FALSE, 'active', TRUE, '+9779811234567'
)
ON CONFLICT (id) DO NOTHING;

-- STEP 6: VERIFY — should see all jobs with salary populated
SELECT
  title, business_name, category,
  salary_type, salary, is_urgent, status
FROM public.jobs
ORDER BY created_at DESC;
