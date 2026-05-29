# Testing & Quality

**Confidence / Verification Status**: `VERIFIED`

## Test Framework
- **Tools**: Standard `flutter_test`.
- **Coverage**: The `test/` directory contains around 40 unit and widget tests, particularly covering `core` helpers, `scanning` logic, `groups` debt calculators, and `shared` utils. All tests currently pass.

## Linter & Formatting
- The project uses `analysis_options.yaml` derived from `flutter_lints`.
- Adhere strictly to Dart formatting rules.

## Recommended Validation Commands
Before submitting code, agents should run:
```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Mocking Strategy
- Real API calls are avoided in UI testing. `AppConstants.hasSupabaseConfig` serves as an integration-level mock toggle. For unit testing Riverpod controllers, override the repository providers to return mock implementations.
