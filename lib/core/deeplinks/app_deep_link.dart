import '../constants/app_constants.dart';

sealed class AppDeepLink {
  const AppDeepLink();

  static AppDeepLink? parse(Uri uri) {
    final token = _friendInviteToken(uri);
    if (token == null) return null;
    return FriendInviteDeepLink(token);
  }

  static String? _friendInviteToken(Uri uri) {
    final segments = uri.pathSegments;
    if (uri.scheme == AppConstants.friendInviteScheme &&
        uri.host == AppConstants.friendInviteHost &&
        segments.length == 2 &&
        segments.first == AppConstants.friendInvitePath) {
      return _validToken(segments.last);
    }

    if (uri.scheme == AppConstants.friendInviteScheme &&
        segments.length == 3 &&
        segments.first == AppConstants.friendInviteHost &&
        segments[1] == AppConstants.friendInvitePath) {
      return _validToken(segments.last);
    }

    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        segments.length >= 3 &&
        segments[segments.length - 3] == AppConstants.friendInviteHost &&
        segments[segments.length - 2] == AppConstants.friendInvitePath) {
      return _validToken(segments.last);
    }

    return null;
  }

  static String? _validToken(String value) {
    final token = Uri.decodeComponent(value).trim();
    if (token.isEmpty || token.length > 128) return null;
    return token;
  }
}

class FriendInviteDeepLink extends AppDeepLink {
  const FriendInviteDeepLink(this.token);

  final String token;

  String get routeLocation => '/friends/invite/${Uri.encodeComponent(token)}';
}
