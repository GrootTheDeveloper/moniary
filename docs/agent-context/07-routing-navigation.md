# Routing & Navigation

**Confidence / Verification Status**: `VERIFIED`

## Setup
- **Package**: `go_router`
- **Location**: `lib/app/app_router.dart`

## Key Behaviors
- **Auth Redirect**: Global redirect logic checks if the user has completed onboarding and if they are logged in. Soft-deleted accounts (`accountStatus.isPending == true`) are redirected to `/login`.
- **Main Shell**: Uses `StatefulShellRoute.indexedStack` to manage bottom navigation tabs (Calendar, Statistics, AI Assistant, Groups, Profile).
- **Transitions**: Custom transitions (`buildSlideTransitionPage`, `buildSlideUpTransitionPage`, `buildFadeTransitionPage`) are used for almost all routes to provide smooth, controlled animations.

## Route Table

| Route | Screen | Notes |
|---|---|---|
| **Auth / Setup** | | |
| `/` | `SplashScreen` | Initial location; redirects to Onboarding, Login, or Shell |
| `/onboarding` | `OnboardingScreen` | Public |
| `/login` | `LoginScreen` | Public |
| `/profile-setup` | `ProfileSetupScreen` | Public; also used for edit mode via query param |
| **Shell (Bottom Nav Tabs)** | | |
| `/calendar` | `CalendarScreen` | Tab 0 |
| `/statistics` | `StatisticsView` | Tab 1 |
| `/assistant` | `AssistantHomeScreen` | Tab 2 |
| `/groups` | `GroupsScreen` | Tab 3 (alias for `GroupListScreen`) |
| `/profile` | `ProfileScreen` | Tab 4 |
| **Global** | | |
| `/app-lock` | `AppLockScreen` | Biometric auth gate; no slide transition |
| **Transactions & Calendar** | | |
| `/camera` | `CameraScreen` | Slides up; accessed via main FAB |
| `/transaction-form` | `TransactionFormScreen` | Slides up; `imagePath` via `state.extra` map |
| `/scanning` | `ScanningScreen` | Slides up |
| `/ocr-review` | `OcrReviewScreen` | Slides up; `OcrReviewArgs` via `state.extra` |
| `/day-detail` | `DayDetailScreen` | `DateTime` via `state.extra`; falls back to today |
| `/transaction-detail` | `TransactionDetailScreen` | `TransactionDetailRouteArgs` via `state.extra`; fade transition |
| `/starred-transactions` | `StarredTransactionsScreen` | Starred transactions list |
| **AI Assistant** | | |
| `/assistant/intro` | `AssistantIntroScreen` | Slides in; first-run assistant onboarding |
| `/assistant/permissions` | `AssistantPermissionScreen` | Slides in; assistant data access consent |
| `/assistant/conversation` | `AssistantConversationScreen` | Slides in; launched from Assistant Home or question library |
| `/assistant/questions` | `AssistantQuestionLibraryScreen` | Suggested question catalog |
| **Groups** | | |
| `/group-detail` | `GroupDetailScreen` | `String` groupId via `state.extra` |
| `/groups/create` | `CreateGroupScreen` | |
| `/groups/invite` | `InviteMemberScreen` | Admin/owner only |
| `/groups/transaction/form` | `AddGroupTransactionScreen` | |
| `/groups/member-amount` | `MemberAmountInputScreen` | |
| `/groups/settlements` | `DebtSettlementScreen` | `String` groupId via `state.extra` |
| `/groups/transaction/detail` | `GroupTransactionDetailScreen` | `String` transactionId via `state.extra`; fade transition |
| **Friends** | | |
| `/friends` | `FriendsScreen` | |
| `/friends/add` | `AddFriendScreen` | Slides up |
| `/friends/invite/:token` | `FriendInviteAcceptScreen` | `token` as path parameter |
| **Settings – Account** | | |
| `/active-sessions` | `ActiveSessionsScreen` | Manage active sessions & remote logout |
| `/delete-account` | `DeleteAccountScreen` | |
| `/delete-account-help` | `DeleteAccountHelpScreen` | |
| `/notification-settings` | `NotificationSettingsScreen` | |
| `/import` | `ImportDataScreen` | |
| `/import-history` | `ImportHistoryScreen` | Lists CSV import history |
| `/import-history/detail` | `ImportDetailScreen` | `ImportHistoryEntry` via `state.extra`; uses `ImportHistoryScreen.detailRoutePath` |
| `/export-data` | `ExportDataScreen` | |
| `/export-history` | `ExportHistoryScreen` | |
| `/export-detail` | `ExportDetailScreen` | `ExportHistoryEntry` via `state.extra` |
| `/export-troubleshooting` | `ExportTroubleshootingScreen` | |
| **Settings – Privacy** | | |
| `/privacy-center` | `PrivacyCenterScreen` | Optional `group` query param (`PrivacyCenterGroup`) |
| `/privacy-policy` | `PrivacyPolicyScreen` | |
| `/privacy-account-faq` | `PrivacyAccountFaqScreen` | |
| `/privacy-contact` | `PrivacyContactScreen` | |
| `/privacy-request-detail` | `PrivacyRequestDetailScreen` | `PrivacyRequestHistoryEntry` via `state.extra` |
| `/permission-rationale` | `PermissionRationaleScreen` | |
| `/data-safety` | `DataSafetyScreen` | |
| `/data-transparency` | `DataTransparencyScreen` | |
| **Settings – Legal** | | |
| `/data-deletion-policy` | `DataDeletionPolicyScreen` | |
| `/data-retention-policy` | `DataRetentionPolicyScreen` | |
| `/third-party-services` | `ThirdPartyServicesScreen` | |
| `/financial-disclaimer` | `FinancialDisclaimerScreen` | |
| `/policy-changelog` | `PolicyChangelogScreen` | |
| `/user-rights-summary` | `UserRightsSummaryScreen` | |
| `/policy-acceptance-notice` | `PolicyAcceptanceNoticeScreen` | |
| `/terms-of-use` | `TermsOfUseScreen` | |
| `/legal-contact` | `LegalContactScreen` | |
| **Settings – Support & Store** | | |
| `/help-center` | `HelpCenterScreen` | |
| `/support-request-checklist` | `SupportRequestChecklistScreen` | |
| `/about-moniary` | `AboutMoniaryScreen` | |
| `/store-compliance-checklist` | `StoreComplianceChecklistScreen` | |
| `/trust-safety` | `TrustSafetyScreen` | |
