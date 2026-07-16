# Dual-device demo runbook

This runbook keeps the Android demo on `main` and the iOS demo on
`hoang/privacy-compliance-multilingual` in lockstep. Do not start the demo
until both branch names resolve to the same release commit.

## 1. Deploy the shared backend first

Both phones must use the same production Supabase project and hosted OCR URL.

1. Compare, then apply the pending migrations as documented in
   [supabase-migrations.md](supabase-migrations.md). This release requires the
   five migrations beginning at `20260716050000`.
2. Deploy the `assistant-chat` Edge Function after setting its Gemini secrets.
3. Deploy the OCR service with its hosted `SUPABASE_URL`,
   `SUPABASE_ANON_KEY`, allowed CORS origins, and a non-zero rate limit. Its
   unauthenticated extraction endpoint must return HTTP 401, not a result.
4. Confirm the app-link association files before testing an HTTPS invite; see
   [android-app-links.md](android-app-links.md).

Never place a service-role key, Gemini key, keystore password, or a real
`mobile.env` in Git.

## 2. Android member (Windows, `main`)

Use a clean clone or ensure there are no local edits. The Gradle wrapper is
checked in, so Android Studio is optional, but JDK 17 and the Android SDK are
required.

```powershell
git switch main
git pull --ff-only origin main
flutter doctor -v
Copy-Item mobile.env.example mobile.env
# Fill mobile.env with the team's shared public client configuration.
flutter pub get
flutter devices
flutter run -d ANDROID_DEVICE_ID --dart-define-from-file=mobile.env
```

For a hand-off APK instead of `flutter run`:

```powershell
flutter build apk --debug --dart-define-from-file=mobile.env
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Use a debug APK for this demo. A release build deliberately fails unless the
team's real `android/key.properties` and upload keystore are present. Keep
`ENABLE_DEV_TOOLS=false` (the default) in every demo artifact.

## 3. iOS owner (macOS, feature branch)

```bash
git switch hoang/privacy-compliance-multilingual
git pull --ff-only origin hoang/privacy-compliance-multilingual
flutter pub get
flutter devices
flutter run -d IOS_DEVICE_ID --dart-define-from-file=mobile.env
```

Install a signed Debug build on the real iPhone. The signing profile must allow
Associated Domains; a simulator build cannot prove that Universal Links work on
the physical device.

Before the first physical install, sign in to Xcode with an Apple Developer
account that belongs to team `FLHU923LV8`. In the Apple Developer identifier
`com.moniary.moniary`, enable **Associated Domains**, **Push Notifications**,
and the App Group `group.com.moniary`; regenerate/download the development
provisioning profile after changing any capability. The profile must contain
`aps-environment` and `com.apple.developer.associated-domains`. If Xcode says
"No Accounts" or that either capability is absent, stop and repair this
provisioning state before retrying the command above.

## 4. Two-phone smoke script

Create two different accounts. Use one account per phone; do not share an
anonymous session.

1. On Android, create a wallet and a personal transaction. On iOS, verify the
   transaction stays private, then create a group and invite the Android user.
2. Open the real HTTPS group invite on Android. It must open Moniary rather
   than only the browser fallback. Accept it and add one group expense.
3. On both phones, verify group balance/activity and the matching notification.
4. Add a recurring transaction with a due date in the device owner's local
   timezone. Relaunch the app on both phones and confirm it posts once only.
5. Scan a receipt on one phone while signed in. Sign out, retry scanning, and
   confirm the app reports authentication required rather than returning OCR
   data.
6. In Settings, submit one privacy request and confirm its history/detail is
   visible. Do not submit five requests merely to test the rate limit on the
   demo account.
7. Grant assistant consent, ask a non-financial budgeting question, then turn
   consent off and confirm the assistant no longer sends context.
8. On iOS, test an HTTPS friend/group invite after installing the signed build.
   On Android, verify the installed APK certificate against `assetlinks.json`
   as described in [android-app-links.md](android-app-links.md).

## Stop conditions

Do not demo a feature that depends on a backend deployment until the migration
history and Edge Function/OCR deployment have been verified in that exact
Supabase project. Capture the failing command, HTTP status, device model, OS,
and the release commit before changing either branch.
