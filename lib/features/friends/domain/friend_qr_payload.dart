import '../../../core/deeplinks/app_deep_link.dart';

class FriendQrPayload {
  const FriendQrPayload._();

  static String? inviteToken(String rawValue) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null) return null;
    final deepLink = AppDeepLink.parse(uri);
    return deepLink is FriendInviteDeepLink ? deepLink.token : null;
  }
}
