# Coding Conventions

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Architecture boundaries

- Preserve `UI -> Riverpod Controller/Provider -> Repository -> Data Source`.
- UI must not call Supabase, HTTP, Storage, or local history files directly.
- Data/domain code must not depend on widgets, `BuildContext`, or l10n.
- Do not rewrite architecture or move broad directory trees without an explicit
  request.

## Runtime data

- Configured/release runtime repositories use Supabase. Debug builds may use
  the in-memory mock mode when dart-defines are absent.
- Missing required Supabase configuration must fail closed for release builds.
- Anonymous users are real Supabase users and remain subject to RLS.

## Localization

- All user-facing text uses `context.l10n.<key>` or localized model extension.
- Add keys to both `app_vi.arb` and `app_en.arb`.
- Never edit generated files in `lib/l10n/gen_l10n/`.

## Async and Riverpod

- Check `context.mounted` after awaiting before using `BuildContext`.
- Do not mutate providers or start I/O from widget `build()`.
- Invalidate all affected family keys after a mutation succeeds.
- Do not silently swallow exceptions; log and surface them through the agreed
  state/error contract.

## Naming and layout

- Classes: PascalCase.
- Files and folders: snake_case.
- Provider variables: lowerCamelCase ending in `Provider`.
- Controllers/notifiers: descriptive class name ending in `Controller` or
  `Notifier`.
- Prefer relative imports, matching the existing repository style.

## UI

- Use `context.moniaryColors` and `context.moniaryTypography`.
- Reuse shared/feature widgets before creating a new primitive.
- Prefer outlined icons and semantic theme colors.
- Amounts that can be privacy-hidden should use the established obscurable
  amount path.

## Generated and secret files

Do not edit `.dart_tool`, generated l10n output, build output, or generated
platform registrants. Never commit Supabase credentials, tokens, signing
material, service-role keys, or Edge Function secrets.
