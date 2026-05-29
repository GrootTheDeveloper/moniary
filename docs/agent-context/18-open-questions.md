# Open Questions

**Confidence / Verification Status**: `VERIFIED`

| Question | Why it matters | Related files | Suggested owner |
|---|---|---|---|
| Are Supabase Row Level Security (RLS) policies enabled in Production? | Security. The Dart code filters by `user_id`, but the backend should enforce it. | `transaction_repository.dart` | DevOps / Backend Admin |
| Does the Production schema exactly match the Dart models? | To prevent parsing exceptions when dealing with `created_at` or `amount` types. | `lib/features/*/domain/models/` | Backend Admin |
| When will the real OCR provider be integrated? | The current scanning feature uses `mock_ocr_service.dart`. We need to swap this out eventually. | `mock_ocr_service.dart` | AI / Backend Team |
| Are the Database tables for Groups and Debts created yet? | If they are not created on Supabase, the Groups feature will only work in Mock Mode. | `group_expense_service.dart` | Backend Admin |
