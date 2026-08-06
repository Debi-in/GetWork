-- ============================================================
-- MIGRATION 06: ADD ADDRESS / LOCATION TO PROFILES TABLE
-- Run this in Supabase SQL Editor to support business profile location
-- ============================================================

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS address TEXT;

-- Verify profiles table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles';
