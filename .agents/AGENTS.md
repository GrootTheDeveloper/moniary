# Agent Instructions

This is a Flutter/Dart project for **Moniary**, a personal finance management app.

## Tech Stack

- **Flutter / Dart**
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** `go_router`
- **Backend:** Supabase (Database, Auth, Storage)
- **Architecture:** Feature-first + Layered (Clean Architecture inspired)
- **Localization:** `flutter_localizations` / ARB-based l10n (Default: Vietnamese)

Read the full agent context before making non-trivial changes:

- `docs/agent-context/00-index.md`
- `docs/agent-context/03-architecture.md`
- `docs/agent-context/04-features.md`
- `docs/agent-context/06-state-management.md`
- `docs/agent-context/07-routing-navigation.md`
- `docs/agent-context/16-agent-task-playbook.md`

## Strict Rules

1. **Do not rewrite architecture** unless explicitly requested.
2. **Do not break boundaries:** `UI -> Riverpod Controller/Notifier -> Repository -> Data Source`.
3. **UI must not call Database/API directly.** Always use the Repository pattern.
4. **Data/Repository layer must not contain UI text, localization logic, or widget logic.**
5. **Preserve both Supabase mode and mock mode.** Always check `AppConstants.hasSupabaseConfig` inside Repositories.
6. **Do not hardcode user-facing UI strings.** Use `context.l10n.<key>`.
7. **Do not swallow exceptions silently.**
8. **Use existing `AppException` and `AppLogger` patterns** for error handling.
9. **Do not edit generated files manually** (e.g., `app_localizations.dart`).
10. **Do not expose secrets,** API keys, Supabase credentials, signing configs, or tokens.
11. **Prefer small, focused changes.**
12. **Add or update tests** when there is an existing test pattern.
13. **If behavior is unclear, document assumptions** before changing code or ask the user.

## Common Commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Documentation

The full agent-readable system documentation lives in:
`docs/agent-context/`
