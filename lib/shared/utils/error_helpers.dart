import '../../core/supabase/app_exception.dart';

/// Returns a user-friendly Vietnamese message for any error.
/// Use this instead of `error.toString()` in SnackBars.
String userFriendlyMessage(Object error) {
  if (error is AppException) {
    if (error.message == 'errorConnection') return 'Lỗi kết nối. Vui lòng thử lại.';
    return error.message;
  }
  return 'Đã xảy ra lỗi. Vui lòng thử lại.';
}
