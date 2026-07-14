# Routing & Navigation

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

## Setup

- Package: `go_router`
- Router: `lib/app/app_router.dart`
- App/deep-link lifecycle: `lib/app/app.dart`
- Initial location: `/`

## Global redirect behavior

The router refreshes from Supabase auth changes plus Riverpod listeners for app
lock and account soft-deletion state.

Redirect order and responsibilities:

1. A signed-in account pending deletion is sent to `/login`.
2. Before onboarding is marked seen, non-onboarding routes go to
   `/onboarding`.
3. Protected routes without a resolved session go to `/login`.
4. When app lock is enabled and unauthenticated, protected routes go to
   `/app-lock`; successful unlock returns to `/calendar`.

Post-auth profile setup, profile survey, and pending friend-invite routing are
decided by the splash/auth application providers rather than duplicated in the
GoRouter redirect.

## Main shell

`StatefulShellRoute.indexedStack` preserves four bottom tabs:

| Index | Route | Screen |
|---:|---|---|
| 0 | `/calendar` | `CalendarScreen` |
| 1 | `/statistics` | `StatisticsView` |
| 2 | `/groups` | `GroupsScreen` / group list |
| 3 | `/profile` | `ProfileScreen` |

The centered camera button opens `/camera`. The financial assistant is a
floating global action that pushes `/assistant`; it is not a fifth shell tab.

## Route table

### Auth and setup

| Route | Screen | Extra/notes |
|---|---|---|
| `/` | `SplashScreen` | Initial decision screen |
| `/onboarding` | `OnboardingScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/profile-setup` | `ProfileSetupScreen` | Public; `?mode=edit` enables edit mode |
| `/profile-survey` | `ProfileSurveyScreen` | Public setup step |
| `/app-lock` | `AppLockScreen` | Biometric gate |
| `/settings` | `SettingsHomeScreen` | Settings hub |

### Transactions and scanning

| Route | Screen | Extra/fallback |
|---|---|---|
| `/camera` | `CameraScreen` | Slide-up camera flow |
| `/transaction-form` | `TransactionFormScreen` | Optional `Map['imagePath']` |
| `/scanning` | `ScanningScreen` | Optional initial image path `String` |
| `/ocr-review` | `OcrReviewScreen` | `OcrReviewArgs`; falls back to calendar |
| `/day-detail` | `DayDetailScreen` | `DateTime`; defaults to now |
| `/transaction-detail` | `TransactionDetailScreen` | `TransactionDetailRouteArgs`; fade transition |
| `/starred-transactions` | `StarredTransactionsScreen` | Important entries |

### Assistant, budgets, and journal

| Route | Screen | Extra/fallback |
|---|---|---|
| `/assistant` | `AssistantHomeScreen` | Global route |
| `/assistant/intro` | `AssistantIntroScreen` | First-run explanation |
| `/assistant/permissions` | `AssistantPermissionScreen` | Data-access consent |
| `/assistant/conversation` | `AssistantConversationScreen` | Optional `AssistantLaunch` |
| `/assistant/questions` | `AssistantQuestionLibraryScreen` | Fixed question catalog |
| `/budgets` | `BudgetScreen` | Monthly budgets |
| `/budgets/category` | `BudgetCategoryDetailScreen` | `BudgetCategoryDetailArgs`; falls back to budgets |
| `/journal/recap` | `MonthlyRecapScreen` | Optional month; defaults to current month |
| `/journal/export` | `JournalExportScreen` | `MonthlyRecap`; falls back to current recap |
| `/journal/collections` | `JournalCollectionsScreen` | Collection list/create |
| `/journal/collection` | `JournalCollectionDetailScreen` | Collection ID; falls back to list |
| `/journal/streak` | `RecordingStreakScreen` | Recording streak |

### Groups and friends

| Route | Screen | Extra/fallback |
|---|---|---|
| `/group-detail` | `GroupDetailScreen` | Group ID |
| `/groups/create` | `CreateGroupScreen` | Slide up |
| `/groups/invite` | `InviteMemberScreen` | Group ID |
| `/groups/invite/:token` | `GroupInviteAcceptScreen` | Shared invite token; recipient previews, joins, or dismisses without joining |
| `/groups/invitations` | `GroupInvitationsScreen` | Persistent direct username/friend invitations; accept or decline |
| `/groups/transaction/form` | `AddGroupTransactionScreen` | `AddGroupTransactionArgs` |
| `/groups/member-amount` | `MemberAmountInputScreen` | `MemberAmountInputArgs` |
| `/groups/settlements` | `DebtSettlementScreen` | Group ID |
| `/groups/transaction/detail` | `GroupTransactionDetailScreen` | Transaction ID; fade |
| `/groups/activity-center` | `GroupActivityCenterScreen` | Optional group ID; without one it opens the notifications-only view |
| `/friends` | `FriendsScreen` | Friend list/requests |
| `/friends/add` | `AddFriendScreen` | Search/add |
| `/friends/invite/:token` | `FriendInviteAcceptScreen` | Path token |

Invalid/missing required group extras fall back to `GroupsScreen`; the group
activity center intentionally accepts a missing group ID for the global
notifications inbox. The friend token route falls back to `FriendsScreen`.

### Settings: account and data

| Route | Screen |
|---|---|
| `/active-sessions` | `ActiveSessionsScreen` |
| `/delete-account` | `DeleteAccountScreen` |
| `/delete-account-help` | `DeleteAccountHelpScreen` |
| `/notification-settings` | `NotificationSettingsScreen` |
| `/import` | `ImportDataScreen` |
| `/import-history` | `ImportHistoryScreen` |
| `/import-history/detail` | `ImportDetailScreen` with `ImportHistoryEntry` |
| `/export-data` | `ExportDataScreen` |
| `/export-history` | `ExportHistoryScreen` |
| `/export-detail` | `ExportDetailScreen` with `ExportHistoryEntry` |
| `/export-troubleshooting` | `ExportTroubleshootingScreen` |

Missing import/export detail extras fall back to the corresponding history
screen.

### Settings: privacy, legal, support, and store

| Route | Screen/notes |
|---|---|
| `/privacy-center` | `PrivacyCenterScreen`; optional `group` query |
| `/privacy-policy` | `PrivacyPolicyScreen` |
| `/privacy-account-faq` | `PrivacyAccountFaqScreen` |
| `/privacy-contact` | `PrivacyContactScreen` |
| `/privacy-request-detail` | `PrivacyRequestDetailScreen` with history entry |
| `/permission-rationale` | `PermissionRationaleScreen` |
| `/data-safety` | `DataSafetyScreen` |
| `/data-transparency` | `DataTransparencyScreen` |
| `/data-deletion-policy` | `DataDeletionPolicyScreen` |
| `/data-retention-policy` | `DataRetentionPolicyScreen` |
| `/third-party-services` | `ThirdPartyServicesScreen` |
| `/financial-disclaimer` | `FinancialDisclaimerScreen` |
| `/policy-changelog` | `PolicyChangelogScreen` |
| `/user-rights-summary` | `UserRightsSummaryScreen` |
| `/policy-acceptance-notice` | `PolicyAcceptanceNoticeScreen` |
| `/terms-of-use` | `TermsOfUseScreen` |
| `/legal-contact` | `LegalContactScreen` |
| `/help-center` | `HelpCenterScreen` |
| `/support-request-checklist` | `SupportRequestChecklistScreen` |
| `/about-moniary` | `AboutMoniaryScreen` |
| `/store-compliance-checklist` | `StoreComplianceChecklistScreen` |
| `/trust-safety` | `TrustSafetyScreen` |

## Adding or changing a route

Define a `static const routePath` on the screen when practical, import the
screen in `app_router.dart`, use a safe typed cast for `state.extra`, and
provide a non-crashing fallback. Update this table in the same change. Route
errors must remain localized through the router `errorBuilder`.
