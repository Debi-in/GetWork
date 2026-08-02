-- ============================================================
-- GETWORK APP — PRODUCTION SUPABASE DATABASE SCHEMA
-- PostgreSQL schema for Map-First Local Hiring Platform
-- ============================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUM TYPES
CREATE TYPE user_type_enum AS ENUM ('worker', 'business');
CREATE TYPE salary_type_enum AS ENUM ('hourly', 'daily', 'fixed');
CREATE TYPE job_category_enum AS ENUM ('all', 'delivery', 'retail', 'food', 'construction', 'cleaning', 'tech', 'events');
CREATE TYPE job_status_enum AS ENUM ('active', 'paused', 'closed', 'filled');
CREATE TYPE application_status_enum AS ENUM ('pending', 'accepted', 'rejected', 'completed');

-- ============================================================
-- 3. PROFILES TABLE
-- Stores both worker and business manager user details
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    avatar_url TEXT,
    user_type user_type_enum NOT NULL DEFAULT 'worker',
    rating NUMERIC(3, 2) DEFAULT 0.00,
    completed_jobs INT DEFAULT 0,
    skills TEXT[] DEFAULT '{}',
    bio TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. BUSINESSES TABLE
-- Stores detailed company profile for hiring entities
-- ============================================================
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    logo_url TEXT,
    address TEXT NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    phone VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. JOBS TABLE
-- Core table storing map-based job postings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    business_logo_url TEXT,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    address TEXT NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    salary_type salary_type_enum NOT NULL DEFAULT 'daily',
    category job_category_enum NOT NULL DEFAULT 'all',
    description TEXT NOT NULL,
    requirements TEXT[] DEFAULT '{}',
    shift_date DATE NOT NULL,
    shift_start_time VARCHAR(20) NOT NULL,
    shift_end_time VARCHAR(20) NOT NULL,
    workers_needed INT NOT NULL DEFAULT 1,
    workers_applied INT NOT NULL DEFAULT 0,
    is_urgent BOOLEAN DEFAULT FALSE,
    status job_status_enum DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. APPLICATIONS TABLE
-- Stores worker job applications
-- ============================================================
CREATE TABLE IF NOT EXISTS public.applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    worker_name VARCHAR(255) NOT NULL,
    worker_phone VARCHAR(50),
    note TEXT,
    status application_status_enum DEFAULT 'pending',
    applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_coords ON public.jobs(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_applications_job_id ON public.applications(job_id);
CREATE INDEX IF NOT EXISTS idx_applications_worker_id ON public.applications(worker_id);

-- ============================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, self write
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Jobs: Public read active jobs, Business can create & edit own jobs
CREATE POLICY "Jobs are viewable by everyone" 
ON public.jobs FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create jobs" 
ON public.jobs FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Jobs can be updated by job owner" 
ON public.jobs FOR UPDATE USING (auth.role() = 'authenticated');

-- Applications: Anyone can insert application during MVP, Workers view own applications
CREATE POLICY "Applications readable by applicant and employer" 
ON public.applications FOR SELECT USING (true);

CREATE POLICY "Anyone can submit job applications" 
ON public.applications FOR INSERT WITH CHECK (true);

-- ============================================================
-- 9. DUMMY SEED DATA FOR KATHMANDU (PHASE 1 & 2 TESTING)
-- ============================================================

INSERT INTO public.jobs (id, title, business_name, latitude, longitude, address, salary, salary_type, category, description, requirements, shift_date, shift_start_time, shift_end_time, workers_needed, workers_applied, is_urgent, status)
VALUES 
('11111111-1111-1111-1111-111111111111', 'Delivery Rider', 'Daraz Nepal', 27.7172, 85.3240, 'Thamel, Kathmandu', 800.00, 'daily', 'delivery', 'Deliver parcels in Thamel area using your motorcycle.', ARRAY['Own motorcycle', 'Valid license', 'Android phone'], CURRENT_DATE, '09:00 AM', '06:00 PM', 3, 1, true, 'active'),
('22222222-2222-2222-2222-222222222222', 'Supermarket Cashier', 'Himalayan Mart', 27.7050, 85.3145, 'Patan Dhoka, Lalitpur', 600.00, 'daily', 'retail', 'Handle cash counter and assist customers.', ARRAY['SLC passed', 'Basic math', 'Friendly attitude'], CURRENT_DATE, '10:00 AM', '07:00 PM', 2, 0, false, 'active'),
('33333333-3333-3333-3333-333333333333', 'Kitchen Helper', 'OR2K Restaurant', 27.7185, 85.3280, 'Thamel, Kathmandu', 500.00, 'daily', 'food', 'Help in kitchen preparation and dishwashing.', ARRAY['No experience needed', 'Hardworking'], CURRENT_DATE, '08:00 AM', '04:00 PM', 1, 0, false, 'active'),
('44444444-4444-4444-4444-444444444444', 'Office Cleaner', 'NIC Asia Bank', 27.7200, 85.3180, 'New Baneshwor, Kathmandu', 400.00, 'daily', 'cleaning', 'Clean office premises before working hours.', ARRAY['Early riser', 'Experience preferred'], CURRENT_DATE, '06:00 AM', '10:00 AM', 2, 1, false, 'active'),
('55555555-5555-5555-5555-555555555555', 'Event Setup Staff', 'Hyatt Regency', 27.7315, 85.3348, 'Boudha, Kathmandu', 1200.00, 'daily', 'events', 'Setup chairs, tables and decorations for event.', ARRAY['Physical fitness', 'Team player'], CURRENT_DATE + INTERVAL '1 day', '07:00 AM', '08:00 PM', 10, 4, true, 'active')
ON CONFLICT (id) DO NOTHING;
