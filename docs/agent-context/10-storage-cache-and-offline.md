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

## Runtime data mode

The app is production-data only. Supabase configuration is mandatory at
startup, and all authenticated or anonymous sessions use backend repositories.
There is no guest/mock repository fallback.

## Local files

The application documents/download directories are used for:

- `moniary_import_history.json`;
- `moniary_export_history.json`;
- `moniary_privacy_request_history.json`;
- exported CSV/XLSX/PDF files;
- permanently saved journal recap PNGs.

Journal sharing may use the temporary directory.
Repositories must surface unreadable/corrupt history files rather than silently
replacing them.

## Supabase image storage

- Private bucket: `transaction-images`.
- Contents include transaction images, profile avatars, group avatars, and group
  transaction images.
- Display paths are resolved to signed URLs with the configured one-hour TTL.

## Offline expectations

There is no general synchronization queue, conflict resolution, or persistent
offline database. A configured Supabase session needs network connectivity for
remote reads/mutations. The assistant, budget summaries, statistics, and journal
recaps can only operate on data their underlying repositories can currently
load.
