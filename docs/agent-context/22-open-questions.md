# Open Questions

**Confidence / Verification Status**: `VERIFIED`

| Question | Why it matters | Related files | Suggested owner |
|---|---|---|---|
| Are Supabase Row Level Security (RLS) policies enabled in Production? | Security. The Dart code filters by `user_id`, but the backend should enforce it. | `transaction_repository.dart` | DevOps / Backend Admin |
| Does the Production schema exactly match the Dart models? | To prevent parsing exceptions when dealing with `created_at` or `amount` types. | `lib/features/*/domain/models/` | Backend Admin |
| Where will the OCR API be hosted for production? | The integrated FastAPI + Tesseract backend currently targets localhost (`http://10.0.2.2:8000` on Android emulator) and needs a reachable HTTPS deployment for release builds. | `backend/ocr/`, `fast_api_ocr_service.dart` | AI / Backend Team |
| Are the Database tables for Groups and Debts created yet? | If they are not created on Supabase, the Groups feature will only work in Mock Mode. | `group_supabase_data_source.dart` | Backend Admin |
