# Moniary Notification Admin

Static admin page for sending custom Moniary inbox and push notifications.

## Flow

1. Open `index.html`.
2. Enter the deployed `admin-notifications` Edge Function URL.
3. Enter `ADMIN_NOTIFICATION_SECRET`.
4. Compose the notification, pick an audience, run dry-run, then send.

The browser calls only the `admin-notifications` Edge Function. The function uses
the Supabase service-role key on the server side to create `app_notifications`.
Those rows enqueue into `notification_outbox`; when `dispatchNow` is true, the
function also invokes `notification-dispatcher` to send FCM immediately.

## Required Supabase secrets

```bash
supabase secrets set ADMIN_NOTIFICATION_SECRET=...
supabase secrets set NOTIFICATION_DISPATCH_SECRET=...
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"project_id":"...","client_email":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"}'
```

Deploy both functions with JWT verification disabled as configured in
`supabase/config.toml`.

## Deploy on Vercel

This folder can be deployed as its own Vercel project. Set the Vercel project
root directory to:

```text
deploy/admin-notifications
```

No service-role key is stored in the browser. The web UI calls
`/api/admin-notifications`; that Vercel Function reads server-side environment
variables and forwards the request to Supabase.

Required Vercel environment variables:

```text
SUPABASE_URL=https://your-project-ref.supabase.co
ADMIN_NOTIFICATION_SECRET=use-a-long-random-admin-only-secret
```

Alternatively, set `ADMIN_NOTIFICATION_FUNCTION_URL` directly if the function
URL cannot be derived from `SUPABASE_URL`. For production, also protect the
Vercel project with Vercel Authentication or a private domain rule.
