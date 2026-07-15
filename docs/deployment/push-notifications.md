# Push notification deployment

The mobile Firebase identifiers and the server FCM credentials are separate.
Public `FIREBASE_*` values belong in ignored `mobile.env`; the Firebase service
account and scheduler secret must exist only in Supabase Edge Function secrets.

## 1. Configure server secrets

Generate one high-entropy dispatcher secret:

```bash
openssl rand -hex 32
```

Create an ignored Edge Function env file containing:

```dotenv
NOTIFICATION_DISPATCH_SECRET=PASTE_GENERATED_VALUE
FCM_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

Upload it, then delete the local temporary file when no longer needed:

```bash
supabase secrets set --env-file supabase/.env.production
```

The service account must belong to the same Firebase project used by the iOS
app and be allowed to send Firebase Cloud Messaging HTTP v1 messages. Never
put the JSON, private key, or dispatcher secret in `mobile.env` or Git.

Create/update the matching Vault entries in the correct Supabase project. The
dispatcher value must exactly equal `NOTIFICATION_DISPATCH_SECRET`:

```sql
select vault.create_secret(
  'https://YOUR_PROJECT_REF.supabase.co',
  'project_url'
);
select vault.create_secret(
  'PASTE_GENERATED_VALUE',
  'notification_dispatch_secret'
);
```

If a name already exists, update that secret instead of creating duplicates.

## 2. Apply and deploy

Apply `20260715140000_notification_dispatcher_hardening.sql`, then deploy the
scheduler-only function without JWT verification. Its private header is the
authentication boundary:

```bash
supabase functions deploy notification-dispatcher --no-verify-jwt
```

After the Edge secrets and Vault values are present, create the dispatcher and
retention jobs from the SQL Editor:

```sql
select * from public.schedule_notification_jobs();
```

The scheduling function first queues one probe invocation (inspect its async
HTTP response), replaces any old jobs of the same names, then schedules
dispatch every minute and notification retention cleanup nightly.

## 3. Verify fail-closed behavior

Calling without the private header must return `401`; a missing or short server
secret must return `500`. Then inspect jobs, HTTP calls, queue state, retries,
and dead letters:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname in (
  'dispatch_notification_outbox',
  'cleanup_expired_notifications'
);

select status_code, content, created
from net._http_response
order by created desc
limit 20;

select id, attempt_count, last_error, sent_at, failed_at, locked_at
from public.notification_outbox
order by created_at desc
limit 50;
```

Test two simultaneous dispatcher calls: each outbox row must be claimed only
once. Test two devices where one FCM token is unregistered and the other is
valid: the valid phone receives once, only the explicit `UNREGISTERED` token is
deactivated, and the outbox row completes without duplicating that delivery.
Transient 408/429/5xx responses retry with exponential backoff and become dead
letters after five claims; permanent payload/configuration errors dead-letter
immediately for investigation.
