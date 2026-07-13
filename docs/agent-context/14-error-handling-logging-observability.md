# Error Handling, Logging & Observability

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Exception contract

`AppException` lives in `lib/core/supabase/app_exception.dart`. Data-layer
code should convert known backend, file, parsing, authentication, and network
failures to an `AppException` with a stable code while preserving useful
developer context in logs.

Do not wrap an existing `AppException` into a generic error. Do not expose
raw `PostgrestException`, file paths, stack traces, or backend messages to UI.

## Logging

`AppLogger` in `lib/shared/utils/app_logger.dart` provides `error`,
`warning`, and `info` over `debugPrint`. Repository/data-source logs should
name the failed operation and pass the error and stack trace.

Global Flutter/Dart handlers in `main.dart` currently also use `debugPrint`.
There is no remote crash/telemetry SDK configured, so production observability
is limited.

## Controller behavior

Controllers expose failures with `AsyncError` or rethrow after setting state
when the caller needs to coordinate navigation/feedback. A failure that affects
user-visible state must not be logged and then converted to success.

On successful mutations, invalidate dependent query providers only after the
repository operation completes.

## Presentation mapping

- Use `userFriendlyMessage(context, error)` or feature-specific l10n mapping.
- Render fixed localized text for states where the technical error does not
  matter.
- Log the stack trace when an async builder receives one and the error is not
  already adequately logged.
- Never render `error.toString()` or raw `AppException.message` as user text.

## Repository pattern

```dart
try {
  return await dataSource.load();
} on PostgrestException catch (error, stackTrace) {
  AppLogger.error('Failed to load feature data', error, stackTrace);
  throw AppException(error.message, code: error.code);
} catch (error, stackTrace) {
  if (error is AppException) rethrow;
  AppLogger.error('Failed to load feature data', error, stackTrace);
  throw const AppException(
    'errorConnection',
    code: 'FEATURE_LOAD_FAILED',
  );
}
```
