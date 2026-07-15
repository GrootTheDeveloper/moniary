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

  // --- FCM/APNs (provided through dart-define; never commit real values) ---
  // Firebase API keys identify a client app; iOS and Android app IDs are
  // always platform-specific even when both apps share one Firebase project.
  static const firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.moniary.moniary',
  );

  static String get firebaseApiKey =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? firebaseIosApiKey
      : firebaseAndroidApiKey;

  static String get firebaseAppId => defaultTargetPlatform == TargetPlatform.iOS
      ? firebaseIosAppId
      : firebaseAndroidAppId;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool hasFirebaseConfigFor(TargetPlatform platform) =>
      (platform == TargetPlatform.iOS || platform == TargetPlatform.android) &&
      firebaseApiKeyFor(platform).isNotEmpty &&
      firebaseAppIdFor(platform).isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      (platform != TargetPlatform.iOS || firebaseIosBundleId.isNotEmpty);

  static bool get hasFirebaseConfig =>
      !kIsWeb && hasFirebaseConfigFor(defaultTargetPlatform);

  static String firebaseApiKeyFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS => firebaseIosApiKey,
        TargetPlatform.android => firebaseAndroidApiKey,
        _ => '',
      };

  static String firebaseAppIdFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS => firebaseIosAppId,
    TargetPlatform.android => firebaseAndroidAppId,
    _ => '',
  };

  static const supabaseLoginCallbackUrl =
      'io.supabase.moniary://login-callback';
  static const supabasePasswordResetCallbackUrl =
      'io.supabase.moniary://reset-password';

  static const googleAuthEnabled = bool.fromEnvironment(
    'ENABLE_GOOGLE_AUTH',
    defaultValue: true,
  );
  static const facebookAuthEnabled = bool.fromEnvironment(
    'ENABLE_FACEBOOK_AUTH',
    defaultValue: false,
  );

  // --- OCR ---
  static const ocrApiUrl = String.fromEnvironment(
    'OCR_API_URL',
    defaultValue:
        'https://ca-moniary-ocr-ocr-eo5b67.happydesert-5a5977c3.southeastasia.azurecontainerapps.io',
  );
  static const ocrRequestTimeout = Duration(seconds: 30);

  /// Call once at app startup. Debug builds can use the in-memory mock mode;
  /// release builds must always provide real Supabase credentials.
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
