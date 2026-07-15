# Project Structure

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

Moniary uses feature-first organization with lightweight layered boundaries.
Not every small feature needs every layer, but code must preserve the direction
`presentation -> application -> domain/repository -> data source`.

## Directory map

| Path | Purpose | Current contents |
|---|---|---|
| `lib/app/` | App composition | `app.dart`, router, theme, shell |
| `lib/core/` | Cross-feature infrastructure | constants, deep links, preferences, camera provider, Supabase bootstrap/providers |
| `lib/features/` | Product modules | 16 feature directories; see below |
| `lib/l10n/` | Localization | Vietnamese/English ARB plus generated output |
| `lib/shared/` | Shared presentation/utilities | design widgets, image/amount widgets, logger, formatters, error helpers |
| `supabase/migrations/` | Versioned database schema | core finance, reports, account lifecycle, groups, friends, budgets, journal, profile survey, RLS and RPCs |
| `supabase/functions/` | Edge Functions | assistant, reports, notifications, reversible account deletion, and scheduler-only permanent cleanup |
| `backend/ocr/` | Receipt OCR API | FastAPI + Tesseract/OpenCV/regex implementation and pytest suite |
| `test/` | Flutter tests | unit and widget tests organized by core/feature |
| `docs/implementation/` | Historical stabilization plan | completed M01-M14 records, not the current roadmap |

## Feature directories

`assistant`, `auth`, `budgets`, `calendar`, `categories`, `friends`, `groups`,
`journal`, `onboarding`, `profile`, `scanning`, `settings`, `splash`,
`statistics`, `transactions`, and `wallets`.

## Typical feature layout

- `presentation/`: screens, sheets, feature widgets.
- `application/`: Riverpod controllers, notifiers, and query providers.
- `domain/`: entities, immutable models, repository interfaces, pure services.
- `data/`: repository implementations, Supabase/mock data sources, local file
  storage, and external services.

Small presentation-only features may omit layers. New database/API access must
still enter through a repository/data source rather than a widget.

## Entrypoints

- `lib/main.dart`: initializes locale data, release configuration checks,
  preferences, Supabase, and `ProviderScope`.
- `lib/app/app.dart`: Material app, localization, app lifecycle lock, and friend
  deep-link handling.
- `lib/app/app_router.dart`: all GoRouter routes and global redirects.
