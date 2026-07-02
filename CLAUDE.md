# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Agent Context

Before making non-trivial changes, read:
- `AGENTS.md` — strict rules and agent instructions
- `docs/agent-context/00-index.md` — full system documentation index (18 files)

## Common Commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test

# Run a single test file
flutter test test/path/to/file_test.dart

# Run without Supabase (Mock Mode)
flutter run

# Run with Supabase
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Run with custom OCR backend (physical device or hosted)
flutter run --dart-define=OCR_API_URL=<url>

# Release build
flutter build apk --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Regenerate localization files after editing .arb files
flutter gen-l10n
```

## Architecture

**Feature-first + Clean Architecture**. Data flows strictly one way:

```
UI (Widgets/Screens)
  → Riverpod Provider (read state)
  → Notifier/Controller (application layer, handles UI logic)
  → Repository (data layer, abstracts Supabase vs. Mock)
  → Supabase / Mock data
```

- `lib/features/<name>/presentation/` — screens and widgets
- `lib/features/<name>/application/` — Riverpod controllers/notifiers
- `lib/features/<name>/domain/` — data models
- `lib/features/<name>/data/` — repositories and services
- `lib/core/` — constants, providers, Supabase client, utils
- `lib/shared/` — reusable widgets and utilities
- `lib/app/` — router (`app_router.dart`), theme

## State Management (Riverpod)

- Use `Provider` for read-only dependencies (repositories, clients).
- Use `Notifier` / `AutoDisposeNotifier` for controllers with synchronous state.
- Use `AsyncNotifier` / `AutoDisposeAsyncNotifier` for controllers fetching async data.
- States use `AsyncValue` — `.loading()`, `.data()`, `.error()`. The UI maps them with `.when()`.
- Provider naming: `<name>Provider`. Controller naming: `<Name>Controller`.

## Mock Mode vs. Supabase Mode

Repositories check `AppConstants.hasSupabaseConfig`. When `false` (no `--dart-define` args in debug), repositories skip Supabase and use in-memory mock data. OCR has **no** mock fallback — the FastAPI backend must be running. Android emulator defaults OCR to `http://10.0.2.2:8000`.

## Routing

`lib/app/app_router.dart` uses `go_router` with `StatefulShellRoute.indexedStack` for the bottom nav tabs (Calendar, Statistics, Groups, Profile). Auth redirects are handled in the global `redirect` callback, which listens to Supabase session state via Riverpod.

## Localization

- Template: `lib/l10n/app_vi.arb` (Vietnamese is default). Also maintain `lib/l10n/app_en.arb`.
- Access in widgets: `context.l10n.<key>`.
- Generated files in `lib/l10n/gen_l10n/` are auto-generated — never edit them manually.
- Run `flutter gen-l10n` after modifying `.arb` files if auto-generation doesn't trigger.

## Key Conventions

- **UI strings**: Never hardcode. Always use `context.l10n.<key>` and add keys to both `.arb` files.
- **Icons**: Always use the `_outlined` variant (e.g., `Icons.home_outlined`). Never `_rounded`, `_filled`, or emojis.
- **Colors**: Never use raw Material colors (`Colors.grey`, `Colors.red`). Use `AppTheme` constants (e.g., `AppTheme.textSubtle`, `AppTheme.danger`).
- **Errors**: Repositories throw `AppException`. Controllers catch it, set `AsyncValue.error`, and log with `AppLogger.error`. Never swallow exceptions silently.
- **BuildContext after async**: Always check `if (!context.mounted) return;` after any `await`.
- **Secrets**: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OCR_API_URL` are passed via `--dart-define` only. Never hardcoded.

## Testing

- Tests live in `test/`. Use `mocktail` for mocking.
- To test a Riverpod controller, override its repository provider with a mock implementation.
- `AppConstants.hasSupabaseConfig` acts as an integration-level mock toggle for repository-level tests.

## Strict Boundaries (do not violate)

1. UI must never call `Supabase.instance.client` directly.
2. Repositories must never contain `BuildContext`, widgets, or localization logic.
3. Controllers must not directly access Supabase — only through repositories.
