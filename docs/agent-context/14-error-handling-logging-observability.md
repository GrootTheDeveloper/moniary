# Error Handling, Logging & Observability

**Confidence / Verification Status**: `VERIFIED`

## Custom Exception Class
- **`AppException`**: Located at `lib/core/supabase/app_exception.dart`.
- All Repositories catch low-level errors (like `PostgrestException`) and throw an `AppException(message, code)`.

## Logging
- **`AppLogger`**: Located at `lib/shared/utils/app_logger.dart`.
- Provides `error`, `info`, and `warning` methods.
- Currently uses `debugPrint`.

## Error UI Mapping
- In Riverpod `AsyncError` states, the UI maps the error message to a user-friendly string using `context.l10n`.
- For silent failures, `AppLogger.error` is used, but exceptions should not be swallowed if they affect user state.

## Example Repository Pattern
```dart
try {
  // DB Call
} on PostgrestException catch (e, st) {
  AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
  throw AppException(e.message, code: e.code);
} catch (e, st) {
  if (e is AppException) rethrow;
  AppLogger.error('Lỗi kết nối', e, st);
  throw const AppException('errorConnection');
}
```
