# Known Risks & Technical Debt

**Confidence / Verification Status**: `VERIFIED`

| Risk | Severity | Evidence | Suggested Action |
|---|---|---|---|
| Hardcoded Mock Mode Toggles | Medium | `TransactionRepository` uses inline checks for `AppConstants.hasSupabaseConfig` in every method. | Long term: Create an interface and two separate implementations (Mock vs Real) managed by Riverpod. |
| In-memory mock data loss | Low | `_mockTransactions` list inside repositories clears on hot restart. | Since it's for testing, it's acceptable, but UI developers must remember this. |
| Supabase RLS Policies unknown | Medium | No SQL migrations folder or schema file is present in the repository. | AI agents cannot guarantee that the user is only fetching their own data on the backend. `user_id` is filtered manually in the Dart code. Confirm RLS is enabled on Supabase dashboard. |
| OCR implementation is mock | Low | `mock_ocr_service.dart` handles the scanning flow currently. | Await real AI/OCR integration phase to replace the mock data. |
| Debt calculation backend | Medium | Group and Debt features are implemented locally with mock data or pending Supabase tables. | Backend tables `expense_groups`, `group_members`, `group_expenses`, `group_expense_splits` must be verified. |
