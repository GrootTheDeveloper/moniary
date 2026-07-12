# System Overview

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## What Moniary does

Moniary is a Flutter personal-finance app for recording income and expenses,
organizing wallets and categories, reviewing calendar/statistics views, setting
monthly category budgets, scanning receipts, and managing shared expenses with
friends. It also includes a local rules-based financial assistant, journal-style
monthly recaps and collections, privacy controls, and import/export workflows.

## Main user journeys

1. **Onboarding, authentication, and setup**: onboarding, email/OAuth or
   anonymous/guest entry, profile setup, then a profile survey that configures
   occupation, currency, and the default wallet.
2. **Transaction capture**: camera-first entry, manual fallback, optional
   FastAPI OCR review, then transaction create/update/delete and importance
   marking.
3. **Review and analysis**: monthly calendar, today grid, search/filtering,
   day/transaction detail, monthly statistics, and category budget progress.
4. **Journal**: monthly recap, recording streak, custom collections, and recap
   image export/share.
5. **Friends and groups**: friend discovery/invites, group expenses, split
   calculation, balances, settlements, and comments.
6. **Account and data management**: app lock, hide balances, notification/report
   settings, CSV import, CSV/XLSX/PDF export, privacy requests, and account
   deletion.

## Main modules

There are 16 feature directories under `lib/features/`:

- Core finance: `transactions`, `calendar`, `statistics`, `wallets`,
  `categories`, `budgets`, `journal`.
- Collaboration: `friends`, `groups`.
- Intelligence/capture: `assistant`, `scanning`.
- App lifecycle/account: `auth`, `onboarding`, `profile`, `settings`, `splash`.

## Runtime modes and external systems

- **Supabase mode**: Auth, PostgreSQL, private Storage, RPCs, migrations, RLS,
  and Edge Functions.
- **Guest/mock data mode**: active when Supabase configuration is absent or the
  user explicitly enters a guest session. Repositories/data sources use
  in-memory mock state; most data is lost when the process restarts.
- **OCR service**: a separate FastAPI service using Tesseract, OpenCV, regex,
  and keyword rules. It is not an LLM service and has no Flutter-side mock
  result fallback.
- **Scheduled email reports**: a Supabase Edge Function integrates with Resend.

## Product defaults

- Vietnamese is the primary locale; English translations are also generated.
- Default currency is VND and timezone is `Asia/Ho_Chi_Minh`.
- The current app uses a warm, light editorial theme. `AppTheme.darkTheme` is
  only a compatibility alias to the light theme.
