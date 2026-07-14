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

The app shows a debug warning on the login screen if these Supabase values were
not compiled into the build. In mock mode all social buttons remain available
for UI testing. In Supabase mode the app shows only providers enabled by the
two `ENABLE_*_AUTH` build flags.

## 2. Supabase URL configuration

In Authentication > URL Configuration, add both exact redirect URLs:

```text
io.supabase.moniary://login-callback
io.supabase.moniary://reset-password
```

Set Site URL to the real production web URL if the product has one. Do not use
localhost as the production Site URL.

## 3. Email signup

Email signup is enabled and email confirmation is required. Configure hosted
SMTP in Authentication > Emails > SMTP Settings before testing with arbitrary
user addresses. `EMAIL_USER` and `EMAIL_PASS` in the local `.env` configure
only local backend processes; they do not configure the hosted Supabase
project.

After signup, open the confirmation email on the same iPhone and verify that
the link returns to Moniary. If delivery or confirmation fails, inspect
Authentication > Audit Logs.

## 4. Google

In Google Cloud Console, use this Supabase callback as an authorized redirect
URI:

```text
https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
```

Configure the OAuth consent screen and add tester accounts while the app is in
testing mode. Add the Google client ID and secret in Supabase, then keep
`ENABLE_GOOGLE_AUTH=true`.

## 5. Facebook

Facebook is intentionally hidden until all of the following are complete:

1. Create/configure the Meta app and Facebook Login product.
2. Add `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback` to Valid OAuth
   Redirect URIs.
3. Add the App ID and App Secret in Supabase and enable Facebook.
4. Put the Meta app in Live mode, or add the physical-device account as an app
   tester during development.
5. Set `ENABLE_FACEBOOK_AUTH=true` in `mobile.env` and rebuild the app.

## 6. Physical-device verification

Test each path from a fresh install or after signing out:

- email signup, confirmation link, and email/password sign-in;
- password-reset email, cold/warm callback, new-password confirmation, and
  sign-in with the new password;
- Google browser launch, consent, callback, and authenticated home screen;
- cold-start callback while the app is terminated;
- cancelled OAuth and a second attempt, which must not fail with a stale PKCE
  verifier;
- Facebook only after its provider-specific setup is complete.

Do not test Facebook while its Supabase provider or build flag is disabled.

## 7. iOS release review

Before submitting an iOS release, verify that the available email/guest login
experience satisfies App Review Guideline 4.8 as an equivalent privacy-focused
alternative to Google and Facebook. This is a release-compliance gate even
though the source implementation and provider callbacks work correctly.
