import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('🛑 ERROR: $message');
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stacktrace:\n$stackTrace');
    }
  }

  static void info(String message) {
    debugPrint('ℹ️ INFO: $message');
  }

  static void warning(String message) {
    debugPrint('⚠️ WARNING: $message');
  }
}
