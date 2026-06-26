# Routing & Navigation

**Confidence / Verification Status**: `VERIFIED`

## Setup
- **Package**: `go_router`
- **Location**: `lib/app/app_router.dart`

## Key Behaviors
- **Auth Redirect**: Global redirect logic checks if the user has completed onboarding and if they are logged in.
- **Main Shell**: Uses `StatefulShellRoute.indexedStack` to manage bottom navigation tabs (Calendar, Statistics, Groups, Profile).
- **Transitions**: Custom transitions (`buildSlideTransitionPage`, `buildSlideUpTransitionPage`, `buildFadeTransitionPage`) are used for almost all routes to provide smooth, controlled animations.

## Route Table

| Route | Screen | Notes |
|---|---|---|
| `/` (Initial) | `SplashScreen` | Redirects to Onboarding or Login or Shell |
| `/onboarding` | `OnboardingScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/profile-setup` | `ProfileSetupScreen` | Public |
| `/restore-account` | `RestoreAccountScreen` | Redirected if account is soft-deleted |
| `/active-sessions` | `ActiveSessionsScreen` | Manage active sessions & remote logout |
| `/calendar` | `CalendarScreen` | Tab 0 |
| `/statistics` | `StatisticsView` | Tab 1 |
| `/groups` | `GroupsScreen` | Tab 2 |
| `/profile` | `ProfileScreen` | Tab 3 |
| `/import` | `ImportDataScreen` | Accessed via Profile |
| `/import-history` | `ImportHistoryScreen` | Lists local CSV import history |
| `/import-history/detail` | `ImportDetailScreen` | Uses `ImportHistoryScreen.detailRoutePath`; expects `ImportHistoryEntry` in `state.extra` |
| `/notification-settings` | `NotificationSettingsScreen` | Accessed via Profile |
| `/scanning` | `ScanningScreen` | Slides up |
| `/ocr-review` | `OcrReviewScreen` | Passes `OcrReviewArgs` |
| `/camera` | `CameraScreen` | Slides up, accessed via Main FAB |
| `/transaction-form` | `TransactionFormScreen` | Used for manual creation or after taking/picking a photo |
| `/app-lock` | `AppLockScreen` | Global lock screen for biometric authentication |
