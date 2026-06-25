import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'Moniary';
  static const defaultTimezone = 'Asia/Ho_Chi_Minh';
  static const defaultLocale = 'vi_VN';

  // --- Supabase ---
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // --- OCR ---
  static const ocrApiUrl = String.fromEnvironment(
    'OCR_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const ocrRequestTimeout = Duration(seconds: 270);

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

  // --- Deep links ---
  static const friendInviteScheme = 'moniary';
  static const friendInviteHost = 'friends';
  static const friendInvitePath = 'invite';

  static String friendInviteLink(String token) {
    return '$friendInviteScheme://$friendInviteHost/'
        '$friendInvitePath/${Uri.encodeComponent(token)}';
  }

  // --- Contact ---
  static const privacyEmail = 'privacy@moniary.app';
  static const supportEmail = 'support@moniary.app';
  static const legalEmail = 'legal@moniary.app';
}
