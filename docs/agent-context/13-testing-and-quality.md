# Testing & Quality

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Test suites

### Flutter

The repository currently contains 37 Dart test files under `test/`. Coverage
includes:

- auth controllers/repository and pending deep-link navigation;
- Supabase exception/session/deep-link helpers;
- transaction search and importance behavior;
- calendar, wallet, category, budget, and import widgets;
- assistant, budget, journal, scanning, friends, and settings repositories/
  controllers;
- group split, validation, balance, debt, and settlement calculations;
- shared currency/error utilities.

Tests use `flutter_test` and `mocktail`. Riverpod tests override dependency
providers; widget tests must avoid real network/API calls.

### OCR backend

`backend/ocr/tests/` is a separate pytest suite for preprocessing, cleanup,
header/items/totals rules, validation, and pipeline fixtures.

## Static analysis

`analysis_options.yaml` includes `flutter_lints` and explicitly enables
`avoid_print`, `unawaited_futures`, `cancel_subscriptions`, and
`close_sinks`.

## Validation commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test

cd backend/ocr
pytest
```

Run the Flutter commands after Dart/config changes. Run pytest when OCR Python
code or fixtures change. Documentation-only changes should still be checked for
broken local links and claims that can be verified mechanically.

Do not write “all tests pass” in durable docs without recording the verification
date/command; test status changes with the codebase.
