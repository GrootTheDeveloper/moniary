import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const appName = 'Moniary';
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );
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
  static const ocrRequestTimeout = Duration(seconds: 8);

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
  static const inviteLinkScheme = 'https';
  static const inviteLinkHost = String.fromEnvironment(
    'INVITE_LINK_HOST',
    defaultValue: 'go.vuivethoima.id.vn',
  );
  static const friendInviteScheme = 'moniary';
  static const friendInviteHost = 'friends';
  static const friendInvitePath = 'invite';
  static const groupInviteHost = 'groups';
  static const groupInvitePath = 'invite';

  static String friendInviteLink(String token) {
    return '$inviteLinkScheme://$inviteLinkHost/$friendInviteHost/'
        '$friendInvitePath/${Uri.encodeComponent(token)}';
  }

  static String groupInviteLink(String token) {
    return '$inviteLinkScheme://$inviteLinkHost/$groupInviteHost/'
        '$groupInvitePath/${Uri.encodeComponent(token)}';
  }

  // --- Contact ---
  static const privacyEmail = 'privacy@moniary.app';
  static const supportEmail = 'support@moniary.app';
  static const legalEmail = 'legal@moniary.app';
}
