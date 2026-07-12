# Feature Inventory

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

## Transactions

- **Purpose**: CRUD for income/expense entries, receipt images, importance flags,
  search, and day/detail views.
- **Layers**: `TransactionComposerController`, query providers,
  `TransactionRepository`, and transaction domain models.
- **Entry flow**: the shell camera action opens `CameraScreen`; camera failures
  surface a localized reason and fall back to the manual create sheet.
- **Storage**: private `transaction-images` paths in Supabase mode; temporary
  local files and in-memory entries in mock mode.

## Calendar

- **Purpose**: month calendar, today image grid, filters, search, summary header,
  day drill-down, and entry points to journal recaps/streaks.
- **State**: `calendarVisibleMonthProvider`, `calendarFilterProvider`, and
  `calendarMonthProvider(month)`.
- **Data**: consumes `TransactionRepository`; it has no independent repository.

## Statistics

- **Purpose**: monthly income/expense/net summaries, category pie chart, trend
  chart, important spending, and top transactions.
- **State**: `statisticsMonthProvider(month)` reads
  `TransactionRepository` directly as a read-only query provider.
- **Navigation**: links from statistics to budgets and transaction detail.

## Budgets

- **Purpose**: monthly per-category expense limits, warning ratios, progress, and
  category transaction drill-down.
- **Layers**: `BudgetController`, `BudgetRepository`,
  `BudgetRepositoryImpl`, and environment-specific budget limit data sources.
- **Data**: combines categories + monthly transactions with
  `category_budget_limits`. Supabase and in-memory mock limit sources are both
  implemented.
- **Routes**: `/budgets` and `/budgets/category`.

## Journal

- **Purpose**: monthly recap, recording streak, custom transaction collections,
  and shareable/savable recap images.
- **Layers**: journal query/action providers, `JournalRepository`, repository
  implementation, and Supabase/mock collection data sources.
- **Data**: recaps and streaks derive from transactions. Collections use
  `journal_collections` and `journal_collection_transactions` in Supabase
  mode and process-local records in mock mode.
- **Routes**: `/journal/recap`, `/journal/export`,
  `/journal/collections`, `/journal/collection`, and `/journal/streak`.

## Financial Assistant

- **Purpose**: answer a fixed catalog of finance questions using the user's
  transaction history: monthly totals, week comparison, daily average, top
  category, repeated spending, and saving suggestions.
- **Important limitation**: this is deterministic on-device/repository logic,
  not a chat model, external AI API, or free-form financial adviser.
- **Consent**: intro/enablement and transaction/wallet/budget access flags are
  stored in `SharedPreferences`. The current snapshot calculation reads
  transactions; wallet/budget flags are reserved for future expansion.
- **Access**: opened as a global route from the floating assistant button, not a
  bottom-navigation tab.

## Wallets and Categories

- **Purpose**: manage financial sources and expense/income classifications.
- **Repositories**: `WalletRepository` and `CategoryRepository`, both with
  Supabase and mock paths selected by `useMockDataModeProvider`.
- **UI**: primarily embedded sections/sheets rather than standalone routes.

## Groups

- **Purpose**: shared expense groups, multiple payer/split modes, integer-safe
  balances, settlements, comments, invitations, and private images.
- **Layers**: `GroupController`, repository contract/implementation,
  Supabase/mock data sources, model mappers, and pure split/settlement services.
- **Backend**: versioned group tables, RPCs, RLS, Storage policies, and views are
  defined in `20260611000000_groups_community.sql`.
- **Invite links**: owner/admin can create a shared link that multiple people
  may use for seven days. The recipient sees a localized preview, can join the
  group through a deep link, and gets an already-member state without an error.
- **Direct invitations**: recipients can reopen username/friend invitations
  from the localized group-invitations inbox, where they can accept or decline
  before the seven-day expiry; the Group tab shows a pending-invitation badge.
- **Screens**: group list/detail/create, invite member, shared-invite
  acceptance, direct-invitations inbox, add/detail transaction, member amount
  input, and debt settlement.

## Friends

- **Purpose**: search by username, request lifecycle, friend removal, friend
  invite links, deep-link acceptance, and inviting a friend to a group.
- **Backend**: friends and invite-link migrations define tables, RLS, and RPCs.
  The Flutter data source uses RPCs and returns minimal profile data.
- **Deep link**: `moniary://friends/invite/<token>`. Pending links survive the
  auth/profile setup decision flow in Riverpod memory.

## Scanning (OCR)

- **Purpose**: upload a receipt to OCR, review parsed fields, and continue into
  transaction creation.
- **Flow**: `ScanningController -> OcrRepository -> OcrService ->
  FastApiOcrService`.
- **Backend**: `backend/ocr/` is rule-based Tesseract + OpenCV + regex/keyword
  matching behind FastAPI. It does not use Ollama, an LLM, or cloud OCR.
- **Environment**: Android emulator default is `http://10.0.2.2:8000`;
  override `OCR_API_URL` for devices or deployment. There is no mock OCR
  response fallback.

## Settings, Privacy, and Data Portability

- **Purpose**: account/profile settings, app lock, hidden balances, active
  sessions, notification/report preferences, CSV import, CSV/XLSX/PDF export,
  privacy requests, account deletion, legal/support/store-compliance screens.
- **Data layer**:
  - `AccountRepository`: account lifecycle, sessions, exports, privacy
    requests, and local export/privacy history.
  - `ImportRepository`: CSV parsing and local import history.
  - `NotificationSettingsRepository`: Supabase or mock notification settings.
  - `PrivacyRepository`: app lock and hidden-balance preferences.
  - `FileActionService`: open/share exported files.
- **Local histories**: import/export/privacy-request histories are JSON files in
  the application documents directory. Corrupt existing history is surfaced and
  not silently overwritten.
- **Import invariant**: a pending history entry must be created before
  transaction creation begins; completion/failure updates the same entry.
- **Reports**: `scheduled-reports` Edge Function generates email summaries and
  uses Resend when configured.

## Profile

- **Purpose**: profile create/edit, username/avatar, and post-setup survey.
- **Setup**: `ProfileSetupScreen` stores name, username, timezone, and avatar.
- **Survey**: `ProfileSurveyScreen` stores occupation/preferred currency and
  creates or updates the default wallet.
- **Data**: `ProfileRepository` supports Supabase and mock profiles.

## Auth, Onboarding, and Splash

- **Auth methods**: email sign-in/sign-up/password reset, Google/Facebook/Apple
  OAuth, anonymous sign-in, and explicit guest/mock session.
- **Account linking**: email, Google, and Apple identity linking paths exist for
  an already signed-in account.
- **Boundary**: controllers manage Riverpod state; `AuthRepository` owns
  Supabase Auth, `initialize_user`, and profile-provider updates.
- **Routing**: splash/post-auth decisions account for onboarding, session,
  profile setup, profile survey, pending friend links, soft deletion, and app
  lock.
