# Mobile authentication setup

The Flutter app reads Supabase configuration at compile time. A root `.env`
file is not loaded automatically, and it contains backend-only secrets that
must never be bundled into the mobile app.

## 1. Create the mobile build configuration

Copy `mobile.env.example` to an ignored local file named `mobile.env`. Put only
public mobile configuration in it:

```dotenv
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=sb_publishable_YOUR_KEY
OCR_API_URL=https://your-ocr-api.example.com
FIREBASE_IOS_API_KEY=YOUR_FIREBASE_IOS_API_KEY
FIREBASE_IOS_APP_ID=1:YOUR_SENDER_ID:ios:YOUR_IOS_APP_ID
FIREBASE_ANDROID_API_KEY=YOUR_FIREBASE_ANDROID_API_KEY
FIREBASE_ANDROID_APP_ID=1:YOUR_SENDER_ID:android:YOUR_ANDROID_APP_ID
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_PROJECT_ID=YOUR_FIREBASE_PROJECT_ID
FIREBASE_IOS_BUNDLE_ID=com.moniary.moniary
ENABLE_GOOGLE_AUTH=true
ENABLE_FACEBOOK_AUTH=false
```

Run on a physical iPhone with:

```bash
flutter devices
flutter run -d DEVICE_ID --dart-define-from-file=mobile.env
```

When starting from Xcode, first generate the Flutter iOS configuration with
the same defines, then open `ios/Runner.xcworkspace`:

```bash
flutter build ios --config-only --dart-define-from-file=mobile.env
open ios/Runner.xcworkspace
```

Use the same file for a release archive:

```bash
flutter build ipa --release --dart-define-from-file=mobile.env
```

The app fails startup when Supabase values are not compiled into the build.
Social buttons are shown only when enabled by the two `ENABLE_*_AUTH` build
flags.

## 2. Supabase URL configuration

In Authentication > URL Configuration, add both exact redirect URLs:

```text
io.supabase.moniary://login-callback
io.supabase.moniary://reset-password
```

Set Site URL to the real production web URL if the product has one. Do not use
localhost as the production Site URL.

Keep **Allow manual linking** enabled. Anonymous-to-Google/Facebook account
upgrades use Supabase identity linking and will be rejected when this setting
is disabled.

## 3. Authentication abuse controls

Anonymous sign-in remains enabled because anonymous data can be upgraded in
place to email, Google, or Facebook. CAPTCHA is disabled, so the mobile build
does not require a site key or verification base URL. In Supabase Dashboard,
keep Authentication > Bot and Abuse Protection > CAPTCHA disabled; otherwise
Supabase will reject password and anonymous authentication requests that do
not contain a token.

1. In Authentication > Rate Limits, keep sign-in/sign-up limits conservative
   and set anonymous sign-ins to no more than **5 per hour per IP address**.
2. Apply `supabase/migrations/20260715120000_cleanup_stale_anonymous_users.sql`.
   It deletes anonymous Auth users inactive for 30 days every night. Upgraded
   email/OAuth accounts are not anonymous and are preserved.

## 4. Email signup

Email signup is enabled and email confirmation is required. Configure hosted
SMTP in Authentication > Emails > SMTP Settings before testing with arbitrary
user addresses. `EMAIL_USER` and `EMAIL_PASS` in the local `.env` configure
only local backend processes; they do not configure the hosted Supabase
project.

After signup, open the confirmation email on the same iPhone and verify that
the link returns to Moniary. If delivery or confirmation fails, inspect
Authentication > Audit Logs.

## 5. Google

In Google Cloud Console, use this Supabase callback as an authorized redirect
URI:

```text
https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
```

Configure the OAuth consent screen and add tester accounts while the app is in
testing mode. Add the Google client ID and secret in Supabase, then keep
`ENABLE_GOOGLE_AUTH=true`.

## 6. Facebook

Facebook is intentionally hidden until all of the following are complete:

1. Create/configure the Meta app and Facebook Login product.
2. Add `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback` to Valid OAuth
   Redirect URIs.
3. Add the App ID and App Secret in Supabase and enable Facebook.
4. Put the Meta app in Live mode, or add the physical-device account as an app
   tester during development.
5. Set `ENABLE_FACEBOOK_AUTH=true` in `mobile.env` and rebuild the app.

## 7. Physical-device verification

### Firebase/APNs push setup

Push notifications are optional at compile time. They are enabled only when
the current platform's API key and app ID plus the shared sender/project IDs
from `mobile.env.example` are present and non-placeholder values. The iOS and
Android client apps must belong to the same Firebase project and both use the
application identifier `com.moniary.moniary`:

1. In Apple Developer, enable **Push Notifications** for the App ID and
   regenerate the development and distribution provisioning profiles.
2. In Firebase Console > Project settings, register both platform apps. Copy
   the iOS API key/app ID, Android API key/app ID, shared sender/project IDs,
   and iOS bundle ID into `mobile.env`. Never use one platform's app ID for the
   other platform.
3. In Firebase Console > Cloud Messaging, upload an APNs authentication key
   (`.p8`) with its Key ID and Apple Team ID. Keep the `.p8` private; it never
   belongs in `mobile.env`, Supabase tables, or Git.
4. Rebuild the app with `--dart-define-from-file=mobile.env`. A hot restart
   cannot change compile-time values or signing entitlements.
5. For server delivery, store the Firebase service-account project ID, client
   email, and private key only as Supabase Edge Function secrets. Do not reuse
   the public mobile API key as a server credential.

Complete the server-side checklist in
[`push-notifications.md`](push-notifications.md) before expecting a registered
device to receive real background notifications.

The Xcode project already declares Push Notifications and remote-notification
background mode for Debug, Profile, and Release. On first authenticated launch,
the device should request permission and create an active row in
`notification_devices`. Signing out must deactivate that device row and delete
the local FCM token. Requesting account deletion deactivates every device for
the account immediately, including other phones.

Verify all four device cases: permission denied, foreground receipt,
background receipt/tap, and terminated-app tap. Then sign out, send again, and
confirm that the signed-out phone receives nothing. Finally sign back in and
confirm a new active token is registered.

Test each path from a fresh install or after signing out:

- email signup, confirmation link, and email/password sign-in;
- anonymous sign-in succeeds without CAPTCHA, and repeated attempts hit the
  configured Supabase rate limit;
- password-reset email, cold/warm callback, new-password confirmation, and
  sign-in with the new password;
- anonymous-to-email upgrade, email callback on the same device, password
  creation, and subsequent email/password sign-in;
- Google browser launch, consent, callback, and authenticated home screen;
- anonymous-to-Google linking, warm/cold callback, identity verification, and
  the final success notification;
- anonymous-to-Facebook linking, warm/cold callback, identity verification,
  and the final success notification;
- cold-start callback while the app is terminated;
- cancelled OAuth and a second attempt, which must not fail with a stale PKCE
  verifier;
- Facebook only after its provider-specific setup is complete.

Do not test Facebook while its Supabase provider or build flag is disabled.

## 8. Account deletion lifecycle

Apply `20260715130000_account_deletion_lifecycle_hardening.sql`, then deploy
only the two functions used by the 30-day grace-period flow:

```bash
supabase functions deploy soft-delete-account
supabase functions deploy garbage-collect --no-verify-jwt
```

`delete-account` is intentionally not deployed: immediate hard deletion would
bypass the advertised restoration period. Permanent deletion is performed only
by `garbage-collect` after eligibility is rechecked in the database.

Generate one high-entropy scheduler secret and store the exact same value in
both locations below. Never add it to `mobile.env` or Git:

```bash
openssl rand -hex 32
supabase secrets set GARBAGE_COLLECT_SECRET=PASTE_GENERATED_VALUE
```

In Supabase Vault, create exactly one secret for each name:

```sql
select vault.create_secret(
  'https://YOUR_PROJECT_REF.supabase.co',
  'project_url'
);
select vault.create_secret(
  'PASTE_GENERATED_VALUE',
  'garbage_collect_secret'
);
```

The nightly cron calls the function with `x-cron-secret`. Calling it without
that header must return `401`; a missing server secret must fail closed with
`500`. Confirm the schedule and recent HTTP responses with:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname = 'garbage_collect_expired_accounts';

select status_code, content, created
from net._http_response
order by created desc
limit 10;
```

Device verification must cover: submit deletion feedback, global sign-out,
sign back in during the grace period, restore successfully, request deletion
again, and verify that restoration after 30 days is rejected. Use a disposable
test account for the final cleanup test.

## 9. iOS release review

Before submitting an iOS release, verify that the available email/guest login
experience satisfies App Review Guideline 4.8 as an equivalent privacy-focused
alternative to Google and Facebook. This is a release-compliance gate even
though the source implementation and provider callbacks work correctly.
