# Build Flavors & Environments

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-15`

## Dart defines

`AppConstants` reads:

| Define | Required | Default/behavior |
|---|---|---|
| `SUPABASE_URL` | Required | Missing configuration stops startup |
| `SUPABASE_ANON_KEY` | Required | Must be present with URL |
| `OCR_API_URL` | Optional at build time | Hosted OCR endpoint in `AppConstants` |
| `APP_VERSION` | Optional | `1.0.0+1` |
| `ENABLE_GOOGLE_AUTH` | Optional | `true`; show Google when configured |
| `ENABLE_FACEBOOK_AUTH` | Optional | `false`; hide Facebook until configured |
| `ENABLE_DEV_TOOLS` | Optional | `false`; keep false for demo/release artifacts |
| `TURNSTILE_SITE_KEY` | Required for protected auth | Public Cloudflare Turnstile widget key |
| `TURNSTILE_BASE_URL` | Required for protected auth | HTTPS origin allowlisted by the Turnstile widget |

`AppConstants.assertSupabaseConfig()` throws in every build mode if either
Supabase value is missing. There is no placeholder client or mock fallback.

## Native flavors

No separate native `dev`/`staging`/`prod` flavors are configured in
Gradle or Xcode. Environment selection currently relies on Dart defines and the
Supabase project/environment used for deployment.

## Common commands

```bash
# Debug against Supabase
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=TURNSTILE_SITE_KEY=... \
  --dart-define=TURNSTILE_BASE_URL=https://auth.example.com/

# Physical device or hosted OCR
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=OCR_API_URL=https://ocr.example.com

# Debug APK for an internal demo (developer controls stay hidden by default)
flutter build apk \
  --debug \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=OCR_API_URL=https://ocr.example.com
```

Release Android artifacts require `android/key.properties`; copy
`android/key.properties.example` and supply the team's upload keystore. The
Gradle build intentionally refuses to package a release with the debug key.

iOS is explicitly kept on CocoaPods (`enable-swift-package-manager: false` in
`pubspec.yaml`) until every native plugin supports Swift Package Manager. This
prevents a Flutter-tool upgrade from silently migrating the Xcode project
during a demo build.

For the synchronized Android/Windows and iOS/macOS demo procedure, use
`docs/deployment/dual-device-demo.md`.

The Android emulator can reach a host OCR service through `10.0.2.2`. A
physical device cannot use that host alias and needs a LAN or HTTPS endpoint.
OCR has no mock result fallback.

## Backend setup

- Supabase schema/functions: `supabase/`.
- AI Chat runs through the `assistant-chat` Supabase Edge Function. Gemini
  credentials are Edge Function secrets, not Flutter `--dart-define` values:
  `GEMINI_API_KEY`, optional `GEMINI_MODEL`, and optional
  `GEMINI_BLOCKED_KEY_SHA256` for comma-separated SHA-256 digests of exposed
  keys that the function must refuse to use.
- OCR installation and runbook: `docs/agent-context/19-ocr-backend.md`.
- Detailed OCR implementation reference: `18-ocr-pipeline.md`.

After rotating the Gemini key, keep the real value in local `.env` and push it
to Supabase with:

```bash
supabase secrets set --env-file .env
supabase functions deploy assistant-chat
```

Do not put real credentials in documentation, launch configurations committed to
Git, or test fixtures.
