# Storage, Cache & Offline Behavior

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## SharedPreferences

Bootstrapped in `lib/core/preferences/` and exposed through Riverpod.

Current preference areas include:

- onboarding seen state;
- preferred currency;
- assistant intro/enablement and data-access flags;
- app lock enabled state;
- hide-balances state.

These preferences are device-local and are not a substitute for synced domain
data.

## Guest/mock data mode

`useMockDataModeProvider` is true when Supabase configuration is missing or the
resolved session is the explicit mock guest. Core finance, profile, groups,
friends, budgets, journal collections, notification settings, and account flows
provide mock behavior.

Most mock repositories/data sources keep static or instance in-memory state.
That state can survive some provider rebuilds but is lost on process restart.
Mock mode is a development/guest experience, not durable offline sync.

## Local files

The application documents/download directories are used for:

- `moniary_import_history.json`;
- `moniary_export_history.json`;
- `moniary_privacy_request_history.json`;
- exported CSV/XLSX/PDF files;
- permanently saved journal recap PNGs.

Journal sharing and mock transaction images may use the temporary directory.
Repositories must surface unreadable/corrupt history files rather than silently
replacing them.

## Supabase image storage

- Private bucket: `transaction-images`.
- Contents include transaction images, profile avatars, group avatars, and group
  transaction images.
- Display paths are resolved to signed URLs with the configured one-hour TTL.
- Mock transaction images are copied to local temporary storage where needed.

## Offline expectations

There is no general synchronization queue, conflict resolution, or persistent
offline database. A configured Supabase session needs network connectivity for
remote reads/mutations. The assistant, budget summaries, statistics, and journal
recaps can only operate on data their underlying repositories can currently
load.
