# Build Flavors & Environments

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Dart defines

`AppConstants` reads:

| Define | Required | Default/behavior |
|---|---|---|
| `SUPABASE_URL` | Required for release | Empty enables shell/mock support in debug |
| `SUPABASE_ANON_KEY` | Required for release | Must be present with URL |
| `OCR_API_URL` | Optional at build time | `http://10.0.2.2:8000` |
| `APP_VERSION` | Optional | `1.0.0+1` |
| `ENABLE_GOOGLE_AUTH` | Optional | `true`; show Google when configured |
| `ENABLE_FACEBOOK_AUTH` | Optional | `false`; hide Facebook until configured |
| `TURNSTILE_SITE_KEY` | Required for live guest sign-in | Public Cloudflare Turnstile widget key |
| `TURNSTILE_BASE_URL` | Required for live guest sign-in | HTTPS origin allowlisted by the Turnstile widget |

`AppConstants.assertSupabaseConfig()` throws in release mode if either Supabase
value is missing. In debug without credentials, bootstrap initializes a
placeholder client so providers can exist while repositories use mock data.

## Native flavors

No separate native `dev`/`staging`/`prod` flavors are configured in
Gradle or Xcode. Environment selection currently relies on Dart defines and the
Supabase project/environment used for deployment.

## Common commands

```bash
# Debug guest/mock-capable build
flutter run

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

# Release APK
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=OCR_API_URL=https://ocr.example.com
```

The Android emulator can reach a host OCR service through `10.0.2.2`. A
physical device cannot use that host alias and needs a LAN or HTTPS endpoint.
OCR has no mock result fallback.

## Backend setup

- Supabase schema/functions: `supabase/`.
- OCR installation and runbook: `docs/agent-context/19-ocr-backend.md`.
- Detailed OCR implementation reference: `18-ocr-pipeline.md`.

Do not put real credentials in documentation, launch configurations committed to
Git, or test fixtures.
