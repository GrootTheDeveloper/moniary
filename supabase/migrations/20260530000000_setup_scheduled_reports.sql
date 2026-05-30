-- Add yearly_summary_enabled to notification_settings
ALTER TABLE public.notification_settings 
ADD COLUMN IF NOT EXISTS yearly_summary_enabled boolean not null default false;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Note: The actual cron job to call the Edge Function requires the project URL and Anon Key.
-- Since those are environment-specific, we recommend setting up the cron job via the Supabase Dashboard,
-- or by running the following snippet manually with your actual URL and KEY:

/*
SELECT cron.schedule(
  'invoke-scheduled-reports',
  '0 0 * * *', -- Run every day at midnight (UTC)
  $$
    SELECT net.http_post(
      url:='https://[PROJECT_REF].supabase.co/functions/v1/scheduled-reports',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer [ANON_KEY]"}'::jsonb,
      body:='{}'::jsonb,
      timeout_milliseconds:=10000
    );
  $$
);
*/
