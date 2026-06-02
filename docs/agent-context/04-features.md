# Features

**Confidence / Verification Status**: `VERIFIED`

## Feature: Transactions
- **Purpose**: Manage expenses and income.
- **Main files**: `features/transactions/`
- **UI screens**: `TransactionFormScreen`, `TransactionDetailScreen`, `CameraScreen`, `DayDetailScreen`.
- **Repository**: `TransactionRepository` (Supports Mock & Supabase modes).
- **Navigation**: The main FAB opens `CameraScreen` for taking/picking photos (or OCR scanning), which then routes to `TransactionFormScreen`.

## Feature: Calendar
- **Purpose**: View transactions in a monthly calendar format.
- **Main files**: `features/calendar/`
- **UI Architecture**: Zero-scroll optimized layout with a deep blue accent theme. Features a seamless "In-Place" toggle: pressing "Today" instantly replaces the month calendar grid with a scrollable 3xN grid of today's images, hiding the month selector for maximum focus. Utilizes `SingleChildScrollView` for filter rows to prevent OOM rendering issues. No separate data layer (consumes `TransactionRepository`).

## Feature: Statistics
- **Purpose**: View financial analytics, charts, and trends.
- **Main files**: `features/statistics/`
- **UI Architecture**: Presentation-only feature. Uses an inline provider `statisticsMonthProvider` that directly consumes `TransactionRepository`. Shows pie charts and bar charts using `fl_chart`.

## Feature: Wallets
- **Purpose**: Manage multiple financial sources (Cash, Bank, E-Wallet, Credit).
- **Main files**: `features/wallets/`
- **Repository**: `WalletRepository` (Supports Mock & Supabase).
- **UI Architecture**: Full clean architecture. Managed primarily via `WalletSection` (bottom sheets).

## Feature: Categories
- **Purpose**: Manage expense/income categories.
- **Main files**: `features/categories/`
- **Repository**: `CategoryRepository` (Supports Mock & Supabase).
- **UI Architecture**: Full clean architecture. Managed primarily via `CategorySection` (bottom sheets).

## Feature: Groups (In-Memory Only)
- **Purpose**: Manage group expenses and calculate debts.
- **Main files**: `features/groups/`
- **UI screens**: `GroupsScreen`, `GroupDetailScreen`, `GroupExpenseFormScreen`, `DebtSummaryScreen`.
- **Services**: `DebtCalculatorService`, `InMemoryGroupExpenseService`.
- **Note**: This is a planned feature. Currently, it is **implemented entirely in-memory** and does NOT sync with Supabase.

## Feature: Scanning (OCR)
- **Purpose**: Extract data from receipts using OCR.
- **Main files**: `features/scanning/`
- **UI screens**: `ScanningScreen`, `OcrReviewScreen`.
- **Services**: `OcrService` (with a `MockOcrService` fallback).
- **Note**: The real OCR backend is not yet integrated. The app currently relies exclusively on the mock implementation.

## Feature: Settings, Privacy & Data Export
- **Purpose**: App settings, legal agreements, privacy requests, data export (CSV/XLSX/PDF), data import (CSV), App Security, and Automated Reports.
- **Main files**: `features/settings/`
- **UI screens**: Massive feature with 30+ screens (ExportDataScreen, ImportDataScreen, NotificationSettingsScreen, PrivacyCenterScreen, AccountDeletionScreen, RestoreAccountScreen, ActiveSessionsScreen, AppLockScreen, etc.).
- **Security Features**: Biometric App Lock (FaceID/TouchID) and Hide Balances mode.
- **Automated Reports**: Uses Supabase Edge Functions + Resend API to send scheduled email reports (Daily/Weekly/Monthly/Yearly).
- **Repository**: `AccountRepository` (handles exports, privacy requests, file actions), `ImportRepository` (handles CSV import and local import history), `PrivacyRepository` (handles Biometric state in SharedPreferences), `NotificationSettingsRepository` (handles email report frequency). Export history and import history are stored locally in JSON format.
- **Export History**: Exported data type selections are stored as stable technical keys (`transactions`, `wallets`, `categories`), and date ranges are stored as raw `start_date`/`end_date` values. Labels are localized only in presentation screens; legacy `date_range` text is still read for older history entries.
- **Export Auth Flow**: CSV/XLSX/PDF export resolves the active user from the Riverpod session path so mock mode exports work with mock anonymous sign-in, while Supabase mode still requires a real signed-in session.
- **Export File Actions**: Opening and sharing exported files is handled from presentation via `FileActionService`; failures are logged and surfaced with localized SnackBars.
- **Import History**: CSV imports create a local history entry before transaction creation starts (`pending`), update it to `completed` with the imported count on success, and mark it `failed` with the partial imported count if the import fails.
- **Import History Guard**: Transaction creation does not start unless the pending import history entry is created successfully, so imported transactions always have a traceable import record.
- **Import CSV Validation**: CSV row scalar fields are parsed with non-throwing validators; malformed dates, amounts, and types stay in the preview as invalid rows with stable error codes instead of being swallowed by empty exception handlers.
- **Import Confirmation Errors**: The import screen stays open and shows a localized error state when confirmation fails; success SnackBars and navigation only run after the controller finishes without an import error.
- **Import Wallet Loading Errors**: The import screen shows a localized retry state when wallets fail to load and does not render raw repository/backend exception details.
- **Recent History Errors**: Import/export entry screens and full history screens surface history loading errors with a localized retry action and log the exception instead of hiding the section silently. If a local import/export history file exists but cannot be parsed, the repository throws an `AppException` and refuses to overwrite that file during new imports or exports.
- **Notification Settings Errors**: Supabase notification settings reads and updates are wrapped as `AppException` values with stable error codes; the UI shows a localized retry state instead of backend exception details.

## Feature: Profile
- **Purpose**: User profile setup and management.
- **Main files**: `features/profile/`
- **Repository**: `ProfileRepository` (Profiles table in Supabase).
- **UI screens**: `ProfileSetupScreen`.

## Feature: Auth & Onboarding
- **Purpose**: User login and introduction.
- **Main files**: `features/auth/`, `features/onboarding/`, `features/splash/`
- **Note**: Auth currently relies on Anonymous Sign-in. Google/Apple/Email sign-ins are marked as "Under Development".
