# Build Flavors & Environments

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-16`

## Dart defines

`AppConstants` reads:

| Define | Required | Default/behavior |
|---|---|---|
| `SUPABASE_URL` | Required | Missing configuration stops startup |
| `SUPABASE_ANON_KEY` | Required | Must be present with URL |
| `OCR_API_URL` | Optional at build time | `http://10.0.2.2:8000` |
| `APP_VERSION` | Optional | `1.0.0+1` |
| `ENABLE_GOOGLE_AUTH` | Optional | `true`; show Google when configured |
| `ENABLE_FACEBOOK_AUTH` | Optional | `false`; hide Facebook until configured |

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
  --dart-define=SUPABASE_ANON_KEY=...

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
