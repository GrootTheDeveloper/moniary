# Known Risks & Technical Debt

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

| Risk | Severity | Evidence | Suggested action |
|---|---|---|---|
| Remote Supabase migration drift | High | The repository has 15 ordered migrations with RLS/RPC/schema changes, including shared-link and direct-invite acceptance functions, but source inspection cannot prove each deployed project is current. | Run migration status/diff against every environment and perform multi-user RLS tests before release. |
| OCR requires a reachable external process | Medium | Flutter always calls `FastApiOcrService`; default host is Android-emulator-only and there is no mock result fallback. | Deploy the FastAPI/Tesseract service over HTTPS, set `OCR_API_URL`, and add health/timeout monitoring. |
| Guest/mock state is volatile | Medium | Transactions, budgets, journal collections, groups/friends, and settings use in-memory mock records. | Clearly label guest persistence limits; add local persistence only if guest data is expected to survive restart. |
| Journal export owns file I/O in presentation | Medium | `journal_export_screen.dart` creates directories/files, writes PNG bytes, and calls sharing directly. | Extract render/save/share orchestration behind an application controller and data service so failures/state are testable. |
| Notification settings domain depends on Flutter UI type | Low | `NotificationSettings` and its repository import Material for `TimeOfDay`. | Store a UI-independent time value in domain/data and map to `TimeOfDay` in presentation. |
| Assistant consent flags exceed current data use | Low | Wallet/budget access flags are persisted, but `buildSnapshot` currently reads transactions only. | Keep consent copy aligned with current access or implement wallet/budget access behind the corresponding flags and tests. |
| Limited production observability | Medium | `AppLogger` and global handlers use `debugPrint`; there is no crash/error telemetry integration. | Choose a privacy-reviewed crash/monitoring solution and redact financial/user data. |
| Device timezone is fixed during setup | Low | Profile setup still writes `Asia/Ho_Chi_Minh` with a TODO to detect device timezone. | Add timezone detection/selection and migration-safe profile updates if multi-region support is required. |
| Scheduled-report production configuration | Medium | Edge Function uses Resend and the source contains a testing sender domain; delivery depends on secrets, cron, and deployed URLs. | Configure verified sender/domain, secrets and cron per environment; add an operational smoke test. |
| Recurring auto-post is not transactional | Low | `RecurringController.materializeDue` creates each due transaction then advances `next_run_date` in separate calls; a crash between the two could re-post on the next run. | Move create+advance into a single RPC if duplicate auto-posts are observed; current catch-up cap bounds blast radius. |
| Recurring migration must be deployed | Medium | New `recurring_transactions` table + RLS in `20260713010000_recurring_transactions.sql` is required before the recurring/cash-flow features work in Supabase mode. | Apply and RLS-test the migration in every environment (see migration-drift row). |
| Single display currency only | Low | `formatMoney`/`formatVnd` render the user's chosen currency, but `amount` columns store no currency and all sums/net-worth/group-split math assume one currency. | Treat multi-currency (per-wallet/transaction currency + FX valuation) as a separate Phase 2; do not mix currencies across wallets until then. |
