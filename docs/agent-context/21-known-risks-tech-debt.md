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
