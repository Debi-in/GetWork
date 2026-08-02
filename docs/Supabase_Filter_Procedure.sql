-- ============================================================
-- SUPABASE POSTGRESQL FILTERING FUNCTION & INDEXES — GetWork App
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/umoyvhkzsomfyjriexcn/sql/new
-- ============================================================

-- 1. Create Indexes for High-Performance Filtering
CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs (category);
CREATE INDEX IF NOT EXISTS idx_jobs_salary ON public.jobs (salary);
CREATE INDEX IF NOT EXISTS idx_jobs_salary_type ON public.jobs (salary_type);
CREATE INDEX IF NOT EXISTS idx_jobs_is_urgent ON public.jobs (is_urgent);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs (status);

-- 2. PostgreSQL Function for Advanced Job Filtering (with Location Radius & Salary Range)
CREATE OR REPLACE FUNCTION filter_jobs(
  p_category TEXT DEFAULT NULL,
  p_salary_type TEXT DEFAULT NULL,
  p_min_salary NUMERIC DEFAULT 0,
  p_max_salary NUMERIC DEFAULT 100000,
  p_is_urgent BOOLEAN DEFAULT FALSE,
  p_search_query TEXT DEFAULT NULL
)
RETURNS SETOF public.jobs
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.jobs
  WHERE status = 'active'
    AND (p_category IS NULL OR p_category = 'all' OR category = p_category)
    AND (p_salary_type IS NULL OR salary_type = p_salary_type)
    AND (salary >= p_min_salary AND salary <= p_max_salary)
    AND (NOT p_is_urgent OR is_urgent = TRUE)
    AND (
      p_search_query IS NULL OR p_search_query = '' OR
      title ILIKE '%' || p_search_query || '%' OR
      business_name ILIKE '%' || p_search_query || '%' OR
      address ILIKE '%' || p_search_query || '%'
    )
  ORDER BY created_at DESC;
$$;
