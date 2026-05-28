import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'Moniary';
  static const defaultTimezone = 'Asia/Ho_Chi_Minh';

  // --- Supabase ---
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Call once at app startup. In release mode, crash if Supabase env is missing.
  static void assertSupabaseConfig() {
    if (kReleaseMode && !hasSupabaseConfig) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be set via --dart-define for release builds.',
      );
    }
  }

  // --- Image ---
  static const imageCompressQuality = 70;

  // --- Storage ---
  static const signedUrlTtlSeconds = 3600; // 1 hour
  static const storageBucket = 'transaction-images';

  // --- Contact ---
  static const privacyEmail = 'privacy@moniary.app';
  static const supportEmail = 'support@moniary.app';
  static const legalEmail = 'legal@moniary.app';
}
