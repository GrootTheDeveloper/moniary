# Known Risks & Technical Debt

**Confidence / Verification Status**: `VERIFIED`

| Risk | Severity | Evidence | Suggested Action |
|---|---|---|---|
| Hardcoded Mock Mode Toggles | Medium | `TransactionRepository` uses inline checks for `AppConstants.hasSupabaseConfig` in every method. | Long term: Create an interface and two separate implementations (Mock vs Real) managed by Riverpod. |
| In-memory mock data loss | Low | `_mockTransactions` list inside repositories clears on hot restart. | Since it's for testing, it's acceptable, but UI developers must remember this. |
| Supabase RLS Policies unknown | Medium | No SQL migrations folder or schema file is present in the repository. | AI agents cannot guarantee that the user is only fetching their own data on the backend. `user_id` is filtered manually in the Dart code. Confirm RLS is enabled on Supabase dashboard. |
| OCR backend requires local FastAPI + Tesseract service | Medium | `backend/ocr/` is a rule-based Tesseract/FastAPI service. It does not use Ollama or any LLM. The service must be running locally or on a reachable host. | Deploy FastAPI + Tesseract service on a reachable host for shared or production use; configure `OCR_API_URL`. |
| Debt calculation backend | Medium | Groups feature has both a `GroupMockDataSource` and `GroupSupabaseDataSource` in Dart, but Supabase backend tables have not been confirmed to exist. | Verify that backend tables (`spending_groups`, `group_members`, `group_transactions`, etc.) exist on Supabase before enabling Groups in production. |
| Localization Architecture Violations (Resolved) | Low | Previously, `AppLocalizations` and UI strings were hardcoded in Domain/Data layers and Legal/Privacy screens. | Resolved by using `BuildContext` extensions in the presentation layer and extracting all UI strings to ARB files. |
