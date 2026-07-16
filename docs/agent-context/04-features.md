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
- **Storage**: private `transaction-images` paths in Supabase Storage.

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
  `BudgetRepositoryImpl`, and the Supabase budget limit data source.
- **Data**: combines categories + monthly transactions with
  `category_budget_limits` in Supabase.
- **Routes**: `/budgets` and `/budgets/category`.

## Journal

- **Purpose**: Money Story monthly recap, recording streak, custom transaction
  collections, and shareable/savable recap images.
- **Layers**: journal query/action providers, `JournalRepository`, repository
  implementation, and the Supabase collection data source.
- **Data**: recaps and streaks derive from transactions. Money Story combines
  income, expenses, net amount, active recording days, top categories, highest
  spend day, and deterministic insight types derived in the repository.
  Collections use `journal_collections` and `journal_collection_transactions`.
- **Routes**: `/journal/recap`, `/journal/export`,
  `/journal/collections`, `/journal/collection`, and `/journal/streak`.

## Financial Assistant

- **Purpose**: answer a fixed catalog of finance questions using the user's
  transaction history: monthly totals, week comparison, daily average, top
  category, repeated spending, and saving suggestions.
- **Implementation**: verified financial snapshots are calculated in the
  repository, rendered locally for exact figures, and may be sent through the
  authenticated `assistant-chat` Supabase Edge Function to Google Gemini for a
  short explanatory response. It is not a free-form financial adviser.
- **Consent**: enablement and transaction/wallet/budget flags are persisted in
  `assistant_preferences`. The Edge Function re-reads those server-side flags,
  validates the question kind, and allowlists snapshot fields before calling
  Gemini; it does not trust client-provided consent markers.
- **Access**: opened as a global route from the floating assistant button, not a
  bottom-navigation tab.

## Wallets and Categories

- **Purpose**: manage financial sources and expense/income classifications.
- **Repositories**: `WalletRepository` and `CategoryRepository`, both backed by
  Supabase.
- **Setup defaults**: profile survey completion seeds the common default
  categories plus occupation-specific defaults for students, office workers,
  freelancers, and business owners. Existing categories are preserved and
  matching names are reactivated/updated instead of duplicated.
- **UI**: primarily embedded sections/sheets rather than standalone routes.

## Groups

- **Purpose**: shared expense groups, multiple payer/split modes, integer-safe
  balances, settlements, comments, invitations, and private images.
- **Expense participants**: each expense can target a selected subset of active
  members. Equal, exact-amount, and member-submitted unequal splits are
  supported; exact shares must sum to the integer transaction total.
- **Layers**: `GroupController`, repository contract/implementation, Supabase
  data sources, model mappers, and pure split/settlement services.
- **Backend**: versioned group tables, RPCs, RLS, Storage policies, and views are
  defined in `20260611000000_groups_community.sql`.
- **Invite links**: owner/admin can create a shared link that multiple people
  may use for seven days. The recipient sees a localized preview through a deep
  link, can explicitly join or dismiss the preview without joining, and gets an
  already-member state without an error.
- **Direct invitations**: recipients can reopen username/friend invitations
  from the localized group-invitations inbox, where they can accept or decline
  before the seven-day expiry; the Group tab shows a pending-invitation badge.
- **Notifications**: group and community notifications have a dedicated Group
  Shell branch with an unread badge. Community content no longer embeds an
  inbox tab; notification preferences remain under Group management.
- **UX organization**: entering a group opens a stateful nested shell with four
  URL-backed destinations: Home, Community, Notifications, and Group
  management. Home is transaction-first: the group header and balance summary
  are followed by the searchable transaction list. Settlement and financial
  summary are contextual flows from Home; album and participation live under
  Community; budget, recurring, notification preferences, public profile,
  audit log, invite, and member controls live under Group management.
  Operational Group notifications remain separate from Community content, and
  child screens preserve the Group Shell bottom navigation.
- **Leave guard**: leaving is allowed only when the member has zero balance, no
  pending/payer-marked/disputed settlement, and no incomplete transaction. A
  successful leave creates both a member-left activity and notifications for
  remaining active members; direct member status updates cannot bypass the
  lifecycle RPC.
- **Member and settlement controls**: owners can transfer ownership; owners and
  admins can remove permitted members only after their balances and settlements
  are resolved. Owners can promote or demote active members between `admin` and
  `member` from the dedicated member screen. Settlement participants can open a
  dispute with a reason.
- **Community UX**: the Community branch is a member-only feed with a real
  composer for text and multi-photo posts. Polls, savings challenges, member
  posts, reactions, and comments are shown as feed cards. Expense transactions
  stay on Group Home, while system/member activities stay in the management
  audit log. Post/comment authors and group admins can edit or delete permitted
  content. Poll votes retain the current member's persisted choice. Savings
  contributions are integer-only, cannot exceed the locked remaining target,
  and automatically complete the challenge. The private Album combines
  transaction receipts with standalone memory/receipt media; media remains
  accessible only to active group members through the private storage bucket.
- **Community creation stability**: post, poll, and challenge forms open
  directly from the stable screen tree; no delayed bottom-sheet-to-dialog
  overlay chain is used. Money inputs use a shared locale-aware integer
  formatter and keep integer domain values.
- **Scoped notification inbox**: Group Shell notification tabs query the same
  unified notification model as the global inbox, filtered by `group_id`.
  Group badge/read-all actions affect only that group. Community updates are
  delivered to this inbox and are not rendered as success/activity cards in
  the Community feed.
- **Screens**: group list/detail/create, invite member, shared-invite
  acceptance, direct-invitations inbox, activity/notifications center,
  Community feed/composer, private album upload, add/detail transaction, member
  amount input, and debt settlement.

## Friends

- **Purpose**: search by username, request lifecycle, friend removal, friend
  invite links, deep-link acceptance, and inviting a friend to a group.
- **Requests visibility**: incoming friend requests live in `FriendsScreen` and
  surface as badges on the Friends title plus Calendar/Profile entry points.
- **Backend**: friends and invite-link migrations define tables, RLS, and RPCs.
  The Flutter data source uses RPCs and returns minimal profile data.
- **Deep link**: invite links are generated as
  `https://go.vuivethoima.id.vn/friends/invite/<token>` and Android also keeps
  legacy `moniary://friends/invite/<token>` parsing for compatibility. Pending
  links survive the auth/profile setup decision flow in Riverpod memory.
- **QR**: users can display their reusable friend invite link as a QR code or
  scan another Moniary friend QR code and review the invite before accepting.

## Scanning (OCR)

- **Purpose**: upload a receipt to OCR, review parsed fields, and continue into
  transaction creation.
- **Flow**: `ScanningController -> OcrRepository -> OcrService ->
  FastApiOcrService`.
- **Backend**: `backend/ocr/` is rule-based Tesseract + OpenCV + regex/keyword
  matching behind FastAPI. It does not use Ollama, an LLM, or cloud OCR.
- **Security**: every extraction sends the current Supabase bearer session;
  the backend resolves that session through Supabase Auth, rate-limits each
  user, bounds concurrent OCR work, and disables raw OCR debug output unless
  the server explicitly opts in.
- **Suggestions**: OCR fields include per-field confidence, source, processing
  time, and a lightweight keyword category suggestion. Autofilled fields are
  visibly marked as AI suggestions and low-confidence values require review.
- **Latency**: camera/gallery input is compressed to 1600 px at quality 72 and
  client extraction times out after eight seconds to keep OCR a utility flow.
- **Environment**: the app defaults to the hosted OCR endpoint. Override
  `OCR_API_URL=http://10.0.2.2:8000` for an Android emulator running a local
  backend. There is no mock OCR response fallback.

## Settings, Privacy, and Data Portability

- **Purpose**: account/profile settings, app lock, hidden balances, active
  sessions, notification/report preferences, CSV import, CSV/XLSX/PDF export,
  privacy requests, account deletion, legal/support/store-compliance screens.
- **Data layer**:
  - `AccountRepository`: account lifecycle, sessions, exports, the server-side
    privacy request inbox, and local export history.
  - `ImportRepository`: CSV parsing and local import history.
  - `NotificationSettingsRepository`: Supabase notification settings.
  - `PrivacyRepository`: app lock and hidden-balance preferences.
- `FileActionService`: open/share exported files.

## Notifications

- **Purpose**: global 30-day inbox for personal, Group, Community, and System
  notification categories.
- **Layers**: `NotificationCenterScreen`, notification Riverpod providers and
  actions controller, `NotificationRepository`, and Supabase data sources.
- **Compatibility**: the global RPC normalizes new `app_notifications` with
  existing `group_notifications` during the migration period.
- **Delivery**: mute preferences affect phone push delivery but do not remove
  inbox history. `flutter_local_notifications` keeps daily reminders and
  provides categorized foreground presentation hooks; FCM/APNs native setup
  still requires project credentials before remote delivery can be enabled.
- **Privacy/retention**: lock-screen copy must not include people names or
  amounts; database queries and cleanup policy retain notification history for
  30 days.
- **Histories**: import/export histories are JSON files in the application
  documents directory. Privacy requests and their administrator responses live
  in the RLS-protected server inbox. Corrupt local histories are surfaced and
  not silently overwritten.
- **Import invariant**: a pending history entry must be created before
  transaction creation begins; completion/failure updates the same entry.
- **Reports**: `scheduled-reports` Edge Function generates email summaries and
  uses Resend when configured.

## Profile

- **Purpose**: profile create/edit, username/avatar, and post-setup survey.
- **Setup**: `ProfileSetupScreen` stores name, username, timezone, and avatar.
- **Survey**: `ProfileSurveyScreen` stores occupation/preferred currency,
  creates or updates the default wallet, and initializes occupation-specific
  category defaults.
- **Data**: `ProfileRepository` stores profiles in Supabase.
- **Display currency**: the chosen currency (`preferredCurrencyProvider`,
  persisted in `SharedPreferences`) drives all money rendering via
  `formatMoney`/`formatVnd` in `lib/shared/utils/currency_formatter.dart`. A
  module-level active currency is synced from the provider (and from prefs at
  startup in `main`) so the many context-free formatting call sites honour the
  selection. Scope is **single display currency** (symbol, decimal digits, digit
  grouping) — amounts are not stored per-currency and there is no FX conversion,
  so mixing currencies across wallets is out of scope until a Phase 2.

## Auth, Onboarding, and Splash

- **Auth methods**: email sign-in/sign-up/password reset, Google/Facebook
  OAuth, and CAPTCHA-protected Supabase anonymous sign-in. There is no demo or
  mock authentication path.
- **Account linking**: email upgrade sends confirmation first, persists the
  originating user/email pair, and only sets a password after the callback;
  Google identity linking persists the originating user, verifies the returned
  Google identity, and only then updates the profile provider.
- **Boundary**: controllers manage Riverpod state; `AuthRepository` owns
  Supabase Auth, `initialize_user`, and profile-provider updates.
- **Routing**: splash/post-auth decisions account for onboarding, session,
  profile setup, profile survey, pending friend links, soft deletion, and app
  lock.
