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
- **UI Architecture**: Zero-scroll optimized layout with a deep blue accent theme. Utilizes `SingleChildScrollView` for filter rows to prevent OOM rendering issues.

## Feature: Groups
- **Purpose**: Manage group expenses and calculate debts.
- **Main files**: `features/groups/`
- **UI screens**: `GroupsScreen`, `GroupDetailScreen`, `GroupExpenseFormScreen`, `DebtSummaryScreen`.
- **Services**: `DebtCalculatorService`, `GroupExpenseService`.

## Feature: Scanning (OCR)
- **Purpose**: Extract data from receipts using OCR.
- **Main files**: `features/scanning/`
- **UI screens**: `ScanningScreen`, `OcrReviewScreen`.
- **Services**: `OcrService` (with a `MockOcrService` fallback).

## Feature: Settings & Profile
- **Purpose**: App settings, legal, privacy, export, profile setup.
- **Main files**: `features/settings/`, `features/profile/`

## Feature: Auth & Onboarding
- **Purpose**: User login and introduction.
- **Main files**: `features/auth/`, `features/onboarding/`, `features/splash/`
