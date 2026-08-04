-- ============================================================
-- AUTO PURGE NOTIFICATIONS > 3 DAYS OLD — GetWork App
-- Run this in Supabase SQL Editor → New Query → Run
-- ============================================================

-- 1. Function to delete notifications and logs older than 3 days
CREATE OR REPLACE FUNCTION public.purge_old_notifications()
RETURNS void AS $$
BEGIN
  -- Delete user notifications older than 3 days
  DELETE FROM public.notifications
  WHERE created_at < NOW() - INTERVAL '3 days';

  -- Delete notification audit logs older than 3 days
  DELETE FROM public.notification_log
  WHERE created_at < NOW() - INTERVAL '3 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger / Cron Job (if pg_cron extension is enabled on Supabase)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    SELECT cron.schedule('purge_old_notifications_job', '0 0 * * *', 'SELECT public.purge_old_notifications()');
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
