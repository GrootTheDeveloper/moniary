# Coding Conventions

**Confidence / Verification Status**: `VERIFIED`

## 1. Clean Architecture Boundaries
- UI must **not** call Database/API directly.
- Data flow: `UI -> Riverpod Controller/Notifier -> Repository -> Data Source`.
- The Data layer (Repository) must **not** contain UI text, localization logic, or widget logic.

## 2. Localization (l10n)
- Do not hardcode user-facing UI strings.
- Use `context.l10n.<key>`.
- Always add keys to both `app_vi.arb` and `app_en.arb`.

## 3. Error Handling
- Repositories throw `AppException`.
- Never swallow exceptions silently. Log them with `AppLogger.error`.
- The UI is responsible for mapping error codes/messages to localized strings.

## 4. BuildContext across Async Gaps
- When using `BuildContext` after an `await`, you must check if the widget is mounted using `if (!context.mounted) return;` or state-specific equivalents.

## 5. Naming
- **Providers**: CamelCase variable name ending with `Provider` (e.g., `userProvider`).
- **Classes**: PascalCase.
- **Files**: snake_case.

## 6. Generated Files
- Never modify files inside `.dart_tool` or `lib/l10n/gen_l10n/` manually.
- Run `flutter gen-l10n` to regenerate translations if needed (though it typically auto-generates on build).

## 7. UI & Iconography
- All icons must use the `_outlined` variant (e.g., `Icons.restaurant_outlined`). Do not use `_rounded`, `_filled`, or generic emojis for UI elements.
- Avoid using hardcoded raw generic Material colors (e.g. `Colors.grey`, `Colors.amber`, `Colors.redAccent`) in the UI. Always map to `AppTheme` constants instead (e.g. `AppTheme.textSubtle`, `AppTheme.amber`, `AppTheme.danger`).
