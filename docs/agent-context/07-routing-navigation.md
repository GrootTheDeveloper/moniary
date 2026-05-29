# Routing & Navigation

**Confidence / Verification Status**: `VERIFIED`

## Setup
- **Package**: `go_router`
- **Location**: `lib/app/app_router.dart`

## Key Behaviors
- **Auth Redirect**: Global redirect logic checks if the user has completed onboarding and if they are logged in.
- **Main Shell**: Uses `StatefulShellRoute.indexedStack` to manage bottom navigation tabs (Calendar, Statistics, Groups, Profile).
- **Transitions**: Custom slide transitions (`buildSlideTransitionPage`, `buildSlideUpTransitionPage`) are used for almost all routes.

## Route Table

| Route | Screen | Notes |
|---|---|---|
| `/` (Initial) | `SplashScreen` | Redirects to Onboarding or Login or Shell |
| `/onboarding` | `OnboardingScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/profile-setup` | `ProfileSetupScreen` | Public |
| `/calendar` | `CalendarScreen` | Tab 0 |
| `/statistics` | `StatisticsView` | Tab 1 |
| `/groups` | `GroupsScreen` | Tab 2 |
| `/profile` | `ProfileScreen` | Tab 3 |
| `/scanning` | `ScanningScreen` | Slides up |
| `/ocr-review` | `OcrReviewScreen` | Passes `OcrReviewArgs` |
| `/transaction-form` | `TransactionFormScreen` | Used for manual/camera creation |
