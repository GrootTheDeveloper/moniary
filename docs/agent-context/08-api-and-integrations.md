# API & Integrations

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-15`

## Supabase

The repository contains a local Supabase project in `supabase/`, including
versioned migrations, seed configuration, and Edge Functions.

### Database areas

- Core: `profiles`, `wallets`, `categories`, `transactions`,
  `notification_settings`.
- Budgets/journal: `category_budget_limits`, `journal_collections`,
  `journal_collection_transactions`.
- Groups: group/member/transaction/payer/share/settlement/comment/invite/
  notification/activity tables and supporting views/functions.
- Friends: `friend_requests`, `friendships`, `friend_invite_links`.
- Account lifecycle: deletion feedback plus functions for soft deletion,
  sessions, and cleanup.

RLS policies and RPCs are defined in migrations. Repository presence proves the
intended schema, not that every remote environment has applied the latest
migration; deployment parity must still be verified.

Group invitations use security-definer RPCs for the recipient inbox because an
`invited` user is intentionally not yet an active group member. Shared links
use a separate token-preview/accept flow; direct username/friend invitations
use `get_my_group_invites`, `accept_direct_group_invite`, and
`decline_direct_group_invite`.

### Auth

`AuthRepository` owns email/password, anonymous, Google/Facebook OAuth,
identity linking, sign-out, password reset, and `initialize_user`. Auth state
feeds `currentSessionProvider` and router refresh.

### Profile setup RPCs

`complete_profile_survey` completes the post-setup survey atomically in
Supabase mode: it initializes the base user data, creates or updates the
default wallet, stores occupation/currency, and calls
`ensure_occupation_categories`. The category RPC preserves existing categories
and inserts or reactivates default category templates for the selected
occupation.

### Storage

The private bucket is `transaction-images`. It stores transaction images,
profile avatars, group avatars, and group transaction images using user/group
scoped paths. Presentation uses `SupabaseImage` and signed URL providers rather
than assuming public URLs.

### Edge Functions

- `scheduled-reports`: claims timezone-aware report periods with bounded
  retries, aggregates totals in Postgres, and sends through a verified Resend
  sender with a stable idempotency key.
- `notification-dispatcher`: reads the notification outbox and sends
  privacy-safe FCM HTTP v1 messages to registered Android/iOS devices. It
  honors global and Group/Community mute preferences, uses leased outbox
  claims, records per-device receipts, and dead-letters bounded failures.
- `soft-delete-account`: starts the account-deletion grace flow.
- `garbage-collect`: scheduler-only permanent cleanup after the 30-day grace
  period. It transfers group ownership when needed, scrubs the retained shared
  ledger profile, removes personal storage, and deletes the Auth user.

Scheduling SQL enables `pg_cron`; project URLs and scheduler secrets are read
from Supabase Vault and are never committed to migrations.

## OCR service

- Flutter flow: `ScanningController -> OcrRepository -> FastApiOcrService`.
- Request: multipart field `file` to `POST {OCR_API_URL}/extract`.
- Backend: `backend/ocr/`, using FastAPI, Tesseract, OpenCV, Pillow, regex, and
  keyword matching.
- The backend also exposes `GET /health` and `POST /extract/base64`.
- It does not use Ollama, an LLM, or cloud OCR.
- OCR configuration is independent of Supabase. There is no fake OCR fallback;
  the service must be reachable for scanning extraction.

## Device integrations

- `camera` and `image_picker`: capture/select receipt and avatar images.
- `local_auth`: app lock.
- `app_links`: HTTPS friend/group invite links plus auth callback/deep-link
  intake.
- `file_picker`: CSV import.
- `open_filex` and `share_plus`: exported file actions and sharing.
- `path_provider`: histories, exports, temporary images, and journal PNGs.

## Financial assistant

The assistant is local deterministic analysis over repository data. It does not
call an external AI provider. Any future model/API integration must be documented
as a new external data processor and remain behind a repository/service boundary.
