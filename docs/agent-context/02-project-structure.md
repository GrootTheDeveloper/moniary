# Project Structure

**Confidence / Verification Status**: `VERIFIED`

The project strictly follows a **Feature-First** directory structure inside `lib/`.

## Directory Map

| Path | Purpose | Notes |
|---|---|---|
| `lib/app/` | App initialization and routing | Contains `app.dart`, `app_router.dart`, `app_theme.dart`, `main_shell_screen.dart` |
| `lib/core/` | Core configurations, providers, and exceptions | `constants/`, `preferences/`, `providers/`, `supabase/` |
| `lib/features/` | Feature modules | Each feature has its own `presentation/`, `application/`, `domain/`, `data/` layers. |
| `lib/l10n/` | Localization files | Contains `.arb` files and generated localizations. |
| `lib/shared/` | Shared UI and Utils | Common widgets, formatters, loggers used across features. |
| `test/` | Tests | Contains unit and widget tests. |

## Feature Module Internal Structure
A typical feature (e.g., `transactions`) follows this internal structure:
- `application/`: Riverpod controllers and notifiers.
- `data/`: Repositories, Services, and API calls.
- `domain/`: Models, Entities, and DTOs.
- `presentation/`: UI Screens, Widgets, and Sheets.

## Entrypoints
- `lib/main.dart`: The main entrypoint. Bootstraps preferences and Supabase.
- `lib/app/app_router.dart`: Defines all `go_router` routes.
