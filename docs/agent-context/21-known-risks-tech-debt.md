# Known Risks & Technical Debt

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

| Risk | Severity | Evidence | Suggested action |
|---|---|---|---|
| Remote Supabase migration drift | High | Source inspection cannot prove the target project has the latest transaction/import, recurring, privacy, wallet, and notification RPC migrations. | Run migration status/diff against every environment and perform multi-user RLS/RPC tests before release. |
| OCR deployment parity | High | The mobile client now sends a Supabase bearer session and the backend verifies it; an old public OCR container would remain unprotected until redeployed. | Deploy the secured FastAPI image first with its Supabase environment, then smoke-test authenticated Android/iOS extraction and monitor health/timeouts. |
| Journal export owns file I/O in presentation | Medium | `journal_export_screen.dart` creates directories/files, writes PNG bytes, and calls sharing directly. | Extract render/save/share orchestration behind an application controller and data service so failures/state are testable. |
| Notification settings domain depends on Flutter UI type | Low | `NotificationSettings` and its repository import Material for `TimeOfDay`. | Store a UI-independent time value in domain/data and map to `TimeOfDay` in presentation. |
| Assistant processor deployment parity | Medium | The Edge Function now revalidates persisted access and filters snapshot fields by question kind, but source cannot prove the deployed function matches. | Deploy `assistant-chat`, run the sanitizer test, and smoke-test enabled/disabled transaction, wallet, and budget consent states. |
| Limited production observability | Medium | `AppLogger` and global handlers use `debugPrint`; there is no crash/error telemetry integration. | Choose a privacy-reviewed crash/monitoring solution and redact financial/user data. |
| Device timezone is fixed during setup | Low | Profile setup still writes `Asia/Ho_Chi_Minh` with a TODO to detect device timezone. | Add timezone detection/selection and migration-safe profile updates if multi-region support is required. |
| Scheduled-report production configuration | Medium | Edge Function uses Resend and the source contains a testing sender domain; delivery depends on secrets, cron, and deployed URLs. | Configure verified sender/domain, secrets and cron per environment; add an operational smoke test. |
| Recurring integrity migration must be deployed | High | Personal materialization is now atomic/idempotent and both personal/group schedules are source-controlled only after the new migration runs. | Apply the latest migrations before distributing either demo build; verify cron jobs and concurrent catch-up against the target project. |
| Single display currency only | Low | `formatMoney`/`formatVnd` render the user's chosen currency, but `amount` columns store no currency and all sums/net-worth/group-split math assume one currency. | Treat multi-currency (per-wallet/transaction currency + FX valuation) as a separate Phase 2; do not mix currencies across wallets until then. |
