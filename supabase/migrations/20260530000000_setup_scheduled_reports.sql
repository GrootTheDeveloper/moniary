-- Add yearly_summary_enabled to notification_settings
ALTER TABLE public.notification_settings 
ADD COLUMN IF NOT EXISTS yearly_summary_enabled boolean not null default false;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Scheduler authentication and timezone-aware delivery are configured by
-- 20260715141000_scheduled_reports_hardening.sql. Never authorize a
-- service-role report job with the public anon key.
