# Scheduled report deployment

Scheduled reports read aggregate financial data with the service role and send
email through Resend. The endpoint is scheduler-only: a public Supabase anon
JWT is not authorization to run it.

## 1. Configure Resend and secrets

Verify the production sender domain in Resend and choose a sender on that
domain, for example `Moniary <noreply@moniary.mobile.com>`. The Resend testing
sender `onboarding@resend.dev` must not be used for production recipients.

Generate a separate scheduler secret with `openssl rand -hex 32`, then put the
following values in the ignored `supabase/production.env` file (`*.env` is
ignored):

```dotenv
RESEND_API_KEY=re_YOUR_KEY
REPORT_EMAIL_FROM="Moniary <noreply@YOUR_VERIFIED_DOMAIN>"
SCHEDULED_REPORTS_SECRET=PASTE_GENERATED_VALUE
```

Upload it with `supabase secrets set --env-file supabase/production.env`.
Never place these values in `mobile.env` or Git. Create/update the matching
Vault secret:

```sql
select vault.create_secret(
  'PASTE_GENERATED_VALUE',
  'scheduled_reports_secret'
);
```

The existing `project_url` Vault value must point to this same Supabase project.

## 2. Apply and deploy

Apply `20260715141000_scheduled_reports_hardening.sql`, then deploy:

```bash
supabase functions deploy scheduled-reports --no-verify-jwt
```

Create the private 15-minute scheduler and 90-day delivery-log cleanup job:

```sql
select * from public.schedule_report_jobs();
```

The first call queues a probe request; inspect its asynchronous HTTP response.
The scheduler respects each profile timezone and `daily_reminder_time`.
Weekly, monthly, and yearly summaries use that time or 07:00 when no daily time
is set.

## 3. Verify privacy and idempotency

Calls without `x-scheduled-reports-secret` must return `401`. Missing Resend,
sender, or scheduler configuration must return `500`. A pending-deletion,
anonymous, unconfirmed, banned, or opted-out account must never be sent a
report.

Each user/type/period has one database delivery row and a stable Resend
`Idempotency-Key`. Resend documents a 24-hour idempotency window:
<https://resend.com/docs/dashboard/emails/idempotency-keys>.

Inspect operations with:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname in (
  'invoke_scheduled_reports',
  'cleanup_scheduled_report_deliveries'
);

select report_type, attempt_count, sent_at, failed_at, last_error
from public.scheduled_report_deliveries
order by created_at desc
limit 50;

select status_code, content, created
from net._http_response
order by created desc
limit 20;
```

Test a user near a timezone date boundary, two concurrent scheduler calls, a
Resend 429 retry, and account deletion while a delivery is pending. Financial
totals are aggregated inside Postgres, so PostgREST's row limit cannot truncate
the report.
