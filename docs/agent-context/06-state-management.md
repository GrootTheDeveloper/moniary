# State Management

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Framework

The project uses `flutter_riverpod` 3.x without code generation.

## Patterns in use

- **`Provider`**: repositories, clients, preferences, router, and other
  read-only dependencies.
- **`NotifierProvider`**: synchronous mutable app state such as onboarding,
  preferred currency, visible calendar month, filters, and pending
  deep links.
- **`FutureProvider` / `FutureProvider.family`**: read queries such as current
  profile, monthly calendar/statistics/budget/recap, journal collections, and
  group/friend data.
- **`StreamProvider`**: Supabase authentication state.
- **`AsyncNotifierProvider`**: mutation workflows and async state machines such
  as auth, transaction composition, import, privacy, assistant, budget, journal,
  profile setup/survey, groups, and friends.

Providers are handwritten and conventionally end in `Provider`; controllers
end in `Controller`.

## Authentication state

- `currentSessionProvider` exposes the current Supabase session.
- `authStateChangesProvider` streams Supabase Auth lifecycle events.
- Anonymous sessions are real Supabase sessions; there is no separate guest or
  mock-session provider.

## Read/query convention

Use family keys that are stable and normalized (for example the first day of a
month or a persistent entity ID). Query providers should read repositories and
return domain/read models; they should not perform UI navigation or show text.

Examples include:

- `calendarMonthProvider(month)`
- `statisticsMonthProvider(month)`
- `monthlyBudgetProvider(month)`
- `monthlyRecapProvider(month)`
- `journalCollectionProvider(collectionId)`

## Mutation convention

Call controller methods through
`ref.read(<controllerProvider>.notifier)`. Controllers set
`AsyncLoading`, then `AsyncData` or `AsyncError`. After a successful
mutation they invalidate every affected query/family key.

A controller may rethrow after storing `AsyncError` when the presentation
caller must decide navigation or feedback. Never both hide the failure and
continue with success UI.

## UI consumption

Use `ref.watch` during build and map async state with `when`, `switch`, or
explicit `hasError/isLoading` handling. Log stack traces where useful and map
errors to localized messages. Do not mutate providers or trigger I/O directly
from widget `build()`.
