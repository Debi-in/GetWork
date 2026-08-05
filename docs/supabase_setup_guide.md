# 🗄️ Supabase Setup Guide — GetWork Live Database

Run the following SQL in your **Supabase Dashboard → SQL Editor → New Query → Run All**.

> [!IMPORTANT]
> Run `04_fix_jobs_schema_match_service.sql` FIRST — this creates the correct schema.

---

## Step 1 — Open Supabase SQL Editor

Go to: `https://supabase.com/dashboard/project/<YOUR_PROJECT_ID>/sql`

---

## Step 2 — Run Migration 04

Copy the contents of [04_fix_jobs_schema_match_service.sql](file:///c:/GetWork%20-%20app/supabase/migrations/04_fix_jobs_schema_match_service.sql) and paste into the SQL editor, then click **Run**.

This creates:
- ✅ `profiles` table
- ✅ `jobs` table (correct columns matching Flutter app)
- ✅ `job_applications` table
- ✅ 6 seed jobs (Kathmandu, Lalitpur, Bhaktapur)
- ✅ `increment_workers_applied` RPC function
- ✅ Public RLS policies

---

## Step 3 — Run Migration for FCM

If not already done, run [fcm_tokens_and_logs.sql](file:///c:/GetWork%20-%20app/supabase/migrations/fcm_tokens_and_logs.sql).

---

## Step 4 — Verify Tables Exist

Run:
```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
```

You should see: `fcm_device_tokens`, `notification_logs`, `profiles`, `jobs`, `job_applications`.

---

## Step 5 — Verify Seed Jobs

```sql
SELECT title, address, salary FROM public.jobs LIMIT 10;
```

---

## What's Now Live 🚀

| Feature | Status |
|---|---|
| Jobs appear on home map | ✅ Live from Supabase |
| Job detail screen | ✅ Live from Supabase |
| Business dashboard metrics | ✅ Live counts from Supabase |
| Business job cards | ✅ Live from Supabase |
| Post Job (Business FAB) | ✅ Writes to Supabase |
| FCM notifications | ✅ Sends to `/topics/all` |
| Native splash screen | ✅ Emerald green |
| Profile management | ✅ Reads/writes Supabase |
