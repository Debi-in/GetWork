-- ============================================================
-- GETWORK APP — PRODUCTION SUPABASE DATABASE SCHEMA (v2.0)
-- Comprehensive PostgreSQL Schema for Local Hiring Platform
-- ============================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUM TYPES
DO $$ BEGIN
    CREATE TYPE user_type_enum AS ENUM ('worker', 'business', 'admin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE availability_status_enum AS ENUM ('available', 'busy', 'on_job', 'interview', 'offline');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE salary_type_enum AS ENUM ('hourly', 'daily', 'weekly', 'monthly', 'project', 'custom');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE job_category_enum AS ENUM ('all', 'delivery', 'retail', 'food', 'construction', 'cleaning', 'tech', 'events', 'hospitality', 'security', 'other');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE job_status_enum AS ENUM ('draft', 'active', 'paused', 'closed', 'filled', 'expired');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE application_status_enum AS ENUM ('pending', 'accepted', 'rejected', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE verification_status_enum AS ENUM ('unverified', 'pending', 'verified', 'rejected');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE document_type_enum AS ENUM ('cv', 'citizenship', 'driving_license', 'passport', 'certificate');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ============================================================
-- 3. PROFILES TABLE
-- Stores worker and business user master profiles
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    avatar_url TEXT,
    user_type user_type_enum NOT NULL DEFAULT 'worker',
    availability_status availability_status_enum DEFAULT 'available',
    rating NUMERIC(3, 2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    completed_jobs INT DEFAULT 0,
    skills TEXT[] DEFAULT '{}',
    languages TEXT[] DEFAULT '{"Nepali", "English"}',
    experience_years INT DEFAULT 0,
    education_level VARCHAR(100),
    bio TEXT,
    preferred_distance_km INT DEFAULT 10,
    cv_url TEXT,
    citizenship_no VARCHAR(100),
    profile_completion_pct INT DEFAULT 50,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. BUSINESSES TABLE
-- Comprehensive business details and branches
-- ============================================================
CREATE TABLE IF NOT EXISTS public.businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    business_type VARCHAR(100),
    description TEXT,
    business_email VARCHAR(255),
    phone VARCHAR(50),
    website VARCHAR(255),
    logo_url TEXT,
    cover_photo_url TEXT,
    address TEXT NOT NULL,
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    opening_time VARCHAR(20),
    closing_time VARCHAR(20),
    verification_status verification_status_enum DEFAULT 'unverified',
    rating NUMERIC(3, 2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. JOBS TABLE (EXPANDED PRODUCTION SCHEMA)
-- Stores detailed map-based job postings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    business_logo_url TEXT,
    
    -- Location & Coordinates
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    address TEXT NOT NULL,
    landmark VARCHAR(255),
    
    -- Category & Description
    category job_category_enum NOT NULL DEFAULT 'other',
    description TEXT NOT NULL,
    
    -- Comprehensive Compensation
    salary_type salary_type_enum NOT NULL DEFAULT 'daily',
    hourly_rate NUMERIC(10, 2),
    daily_rate NUMERIC(10, 2),
    weekly_rate NUMERIC(10, 2),
    monthly_rate NUMERIC(10, 2),
    total_project_salary NUMERIC(10, 2),
    estimated_monthly_salary NUMERIC(10, 2),
    
    -- Schedule & Shift Times
    job_start_date DATE NOT NULL,
    job_end_date DATE,
    is_continuous_hiring BOOLEAN DEFAULT FALSE,
    working_days TEXT[] DEFAULT '{"Monday","Tuesday","Wednesday","Thursday","Friday"}',
    break_minutes INT DEFAULT 30,
    shift_start_time VARCHAR(20) NOT NULL,
    shift_end_time VARCHAR(20) NOT NULL,
    
    -- Benefits (Booleans)
    free_lunch BOOLEAN DEFAULT FALSE,
    free_dinner BOOLEAN DEFAULT FALSE,
    free_breakfast BOOLEAN DEFAULT FALSE,
    transport_provided BOOLEAN DEFAULT FALSE,
    accommodation_provided BOOLEAN DEFAULT FALSE,
    festival_bonus BOOLEAN DEFAULT FALSE,
    performance_bonus BOOLEAN DEFAULT FALSE,
    overtime_pay BOOLEAN DEFAULT FALSE,
    uniform_provided BOOLEAN DEFAULT FALSE,
    insurance_covered BOOLEAN DEFAULT FALSE,
    
    -- Worker Requirements
    minimum_age INT DEFAULT 18,
    maximum_age INT DEFAULT 60,
    preferred_gender VARCHAR(20) DEFAULT 'Any',
    experience_months INT DEFAULT 0,
    education_level VARCHAR(100) DEFAULT 'None',
    required_languages TEXT[] DEFAULT '{"Nepali"}',
    required_skills TEXT[] DEFAULT '{}',
    requirements_text TEXT[] DEFAULT '{}',
    
    -- Contact & Application Preferences
    allow_apply BOOLEAN DEFAULT TRUE,
    allow_phone BOOLEAN DEFAULT FALSE,
    allow_whatsapp BOOLEAN DEFAULT FALSE,
    allow_chat BOOLEAN DEFAULT TRUE,
    contact_phone VARCHAR(50),
    whatsapp_number VARCHAR(50),
    
    -- Status & Visibility Flags
    workers_needed INT NOT NULL DEFAULT 1,
    is_urgent BOOLEAN DEFAULT FALSE,
    is_featured BOOLEAN DEFAULT FALSE,
    status job_status_enum DEFAULT 'active',
    expiry_date TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    repost_count INT DEFAULT 0,
    
    -- Analytics Counters
    views_count INT DEFAULT 0,
    unique_views_count INT DEFAULT 0,
    saved_count INT DEFAULT 0,
    applications_count INT DEFAULT 0,
    accepted_count INT DEFAULT 0,
    rejected_count INT DEFAULT 0,
    completed_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. APPLICATIONS TABLE
-- Connects workers with job postings
-- ============================================================
CREATE TABLE IF NOT EXISTS public.applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    worker_name VARCHAR(255) NOT NULL,
    worker_phone VARCHAR(50),
    worker_note TEXT,
    employer_note TEXT,
    salary_offered NUMERIC(10, 2),
    status application_status_enum DEFAULT 'pending',
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    UNIQUE(job_id, worker_id)
);

-- ============================================================
-- 7. JOB VIEWS TABLE (Analytics & Fraud Prevention)
-- Tracks views without fake duplication
-- ============================================================
CREATE TABLE IF NOT EXISTS public.job_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    stay_duration_seconds INT DEFAULT 0
);

-- ============================================================
-- 8. SAVED JOBS TABLE (Bookmarks)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.saved_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    saved_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(worker_id, job_id)
);

-- ============================================================
-- 9. CONVERSATIONS & MESSAGES (Real-Time In-App Chat)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.conversation_members (
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10. NOTIFICATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 11. WORKER & BUSINESS REVIEWS TABLE
-- 2-Way Rating System
-- ============================================================
CREATE TABLE IF NOT EXISTS public.worker_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reviewer_business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.business_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    reviewer_worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 12. WORKER DOCUMENTS TABLE
-- Citizenship, License, CV
-- ============================================================
CREATE TABLE IF NOT EXISTS public.worker_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    document_type document_type_enum NOT NULL,
    file_url TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. JOB TEMPLATES TABLE
-- Rapid 1-Click Reusable Job Postings for Employers
-- ============================================================
CREATE TABLE IF NOT EXISTS public.job_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    template_name VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    category job_category_enum NOT NULL DEFAULT 'other',
    description TEXT NOT NULL,
    salary_type salary_type_enum NOT NULL DEFAULT 'daily',
    daily_rate NUMERIC(10, 2),
    hourly_rate NUMERIC(10, 2),
    requirements_text TEXT[] DEFAULT '{}',
    free_lunch BOOLEAN DEFAULT FALSE,
    transport_provided BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 14. SPAM & SAFETY REPORTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.job_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 15. INDEXES FOR HIGH-PERFORMANCE MAP & SEARCH
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_jobs_coords ON public.jobs(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_urgent ON public.jobs(is_urgent) WHERE is_urgent = TRUE;
CREATE INDEX IF NOT EXISTS idx_applications_job ON public.applications(job_id);
CREATE INDEX IF NOT EXISTS idx_applications_worker ON public.applications(worker_id);
CREATE INDEX IF NOT EXISTS idx_job_views_job ON public.job_views(job_id);
CREATE INDEX IF NOT EXISTS idx_saved_jobs_worker ON public.saved_jobs(worker_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);

-- ============================================================
-- 16. ROW LEVEL SECURITY (RLS) POLICIES ON ALL 14 TABLES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_reports ENABLE ROW LEVEL SECURITY;

-- Permissive development policies
DO $$ BEGIN CREATE POLICY "Profiles viewable by everyone" ON public.profiles FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Profiles manageability" ON public.profiles FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN CREATE POLICY "Businesses viewable by everyone" ON public.businesses FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Businesses manageability" ON public.businesses FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN CREATE POLICY "Jobs viewable by everyone" ON public.jobs FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Jobs manageability" ON public.jobs FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN CREATE POLICY "Applications viewable by everyone" ON public.applications FOR SELECT USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Applications manageability" ON public.applications FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN CREATE POLICY "Saved jobs manageability" ON public.saved_jobs FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Job views manageability" ON public.job_views FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Notifications manageability" ON public.notifications FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Conversations manageability" ON public.conversations FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Conversation members manageability" ON public.conversation_members FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Messages manageability" ON public.messages FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Worker reviews manageability" ON public.worker_reviews FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Business reviews manageability" ON public.business_reviews FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Worker documents manageability" ON public.worker_documents FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Job templates manageability" ON public.job_templates FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE POLICY "Job reports manageability" ON public.job_reports FOR ALL USING (true); EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ============================================================
-- 17. RICH KATHMANDU SEED DATA (v2.0)
-- ============================================================
INSERT INTO public.jobs (
    id, title, business_name, latitude, longitude, address, landmark, category, description,
    salary_type, daily_rate, hourly_rate, estimated_monthly_salary, job_start_date,
    shift_start_time, shift_end_time, free_lunch, transport_provided, overtime_pay,
    workers_needed, is_urgent, is_featured, status, allow_whatsapp, whatsapp_number
) VALUES 
(
    '11111111-1111-1111-1111-111111111111', 'Delivery Rider', 'Daraz Nepal', 27.7172, 85.3240,
    'Thamel, Kathmandu', 'Near Garden of Dreams', 'delivery', 'Deliver express parcels across Thamel & Lazimpat area.',
    'daily', 900.00, 112.50, 23400.00, CURRENT_DATE, '09:00 AM', '05:00 PM', true, false, true,
    3, true, true, 'active', true, '+9779801122334'
),
(
    '22222222-2222-2222-2222-222222222222', 'Supermarket Cashier', 'Himalayan Mart', 27.7050, 85.3145,
    'Patan Dhoka, Lalitpur', 'Opposite Labim Mall', 'retail', 'Operate barcode scanner and handle cash register transactions.',
    'daily', 700.00, 87.50, 18200.00, CURRENT_DATE, '10:00 AM', '06:00 PM', true, true, false,
    2, false, false, 'active', false, NULL
),
(
    '33333333-3333-3333-3333-333333333333', 'Kitchen Prep Assistant', 'OR2K Restaurant', 27.7185, 85.3280,
    'Thamel, Kathmandu', 'Near Mandala Street', 'food', 'Assist executive chef with vegetable washing, chopping, and kitchen prep.',
    'daily', 650.00, 81.25, 16900.00, CURRENT_DATE, '08:00 AM', '04:00 PM', true, false, true,
    1, false, true, 'active', true, '+9779841234567'
),
(
    '44444444-4444-4444-4444-444444444444', 'Event Setup Staff', 'Hyatt Regency', 27.7315, 85.3348,
    'Boudha, Kathmandu', 'Near Taragaon Museum', 'events', 'Setup banquet tables, lighting, and decorative stages for international convention.',
    'daily', 1300.00, 130.00, 33800.00, CURRENT_DATE + INTERVAL '1 day', '07:00 AM', '05:00 PM', true, true, true,
    10, true, true, 'active', true, '+9779851098765'
)
ON CONFLICT (id) DO NOTHING;
