# API & Integrations

**Confidence / Verification Status**: `VERIFIED`

## Supabase Database
- Tables interacted with: `transactions`, `wallets`, `categories`, `profiles`.
- Note: The **Groups** feature is currently entirely in-memory and does not interact with Supabase yet.
- Mock Mode is built into the repositories. If `AppConstants.hasSupabaseConfig` is false, DB calls are bypassed, and data is kept in-memory.

## Supabase Auth
- Uses `supabaseClient.auth`. The session state stream triggers router refreshes.

## Supabase Storage
- Bucket: `transaction-images`
- Handles uploading receipt images. In Mock Mode, images are written to local temporary storage instead.

## OCR Service
- Found in `features/scanning/data/ocr_service.dart`.
- There is a `MockOcrService` for use before the real AI provider is connected.

## Resend API & Edge Functions
- Supabase Edge Function (`monthly-report`) integrates with Resend API.
- Generates HTML email reports summarizing income, expenses, and top categories.
- Frequencies: Daily, Weekly, Monthly, Yearly.
- Invoked automatically via `pg_cron` (planned) or triggered via API.
