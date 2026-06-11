# API & Integrations

**Confidence / Verification Status**: `VERIFIED`

## Supabase Database
- Tables interacted with: `transactions`, `wallets`, `categories`, `profiles`.
- The **Groups & Community** feature uses group tables, RLS, private Storage paths, and RPCs for atomic split/settlement updates.
- Mock Mode is built into the repositories. If `AppConstants.hasSupabaseConfig` is false, DB calls are bypassed, and data is kept in-memory.

## Supabase Auth
- Uses `supabaseClient.auth`. The session state stream triggers router refreshes.

## Supabase Storage
- Bucket: `transaction-images`
- Handles uploading receipt images. In Mock Mode, images are written to local temporary storage instead.

## OCR Service
- Flutter integration is in `features/scanning/data/`.
- `FastApiOcrService` uploads the selected receipt as multipart field `file`
  to `POST {OCR_API_URL}/extract`.
- `OcrRepository` keeps API access behind the application controllers.
- The FastAPI + Ollama backend is in `backend/ocr/`.
- OCR always uses FastAPI. Android emulator builds default to
  `http://10.0.2.2:8000`; set `OCR_API_URL` for other environments.
- OCR configuration is independent of Supabase, so FastAPI OCR also works
  while repositories use mock Supabase data.

## Resend API & Edge Functions
- Supabase Edge Function (`monthly-report`) integrates with Resend API.
- Generates HTML email reports summarizing income, expenses, and top categories.
- Frequencies: Daily, Weekly, Monthly, Yearly.
- Invoked automatically via `pg_cron` (planned) or triggered via API.
