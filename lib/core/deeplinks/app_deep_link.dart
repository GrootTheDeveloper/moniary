import '../constants/app_constants.dart';

sealed class AppDeepLink {
  const AppDeepLink();

  String get routeLocation;

  static AppDeepLink? parse(Uri uri) {
    final friendToken = _inviteToken(
      uri,
      host: AppConstants.friendInviteHost,
      path: AppConstants.friendInvitePath,
    );
    if (friendToken != null) return FriendInviteDeepLink(friendToken);

    final groupToken = _inviteToken(
      uri,
      host: AppConstants.groupInviteHost,
      path: AppConstants.groupInvitePath,
    );
    if (groupToken != null) return GroupInviteDeepLink(groupToken);
    return null;
  }

  static String? _inviteToken(
    Uri uri, {
    required String host,
    required String path,
  }) {
    final segments = uri.pathSegments;
    if (uri.scheme == AppConstants.friendInviteScheme &&
        uri.host == host &&
        segments.length == 2 &&
        segments.first == path) {
      return _validToken(segments.last);
    }

    if (uri.scheme == AppConstants.friendInviteScheme &&
        segments.length == 3 &&
        segments.first == host &&
        segments[1] == path) {
      return _validToken(segments.last);
    }

    if (uri.scheme == AppConstants.inviteLinkScheme &&
        uri.host == AppConstants.inviteLinkHost &&
        segments.length >= 3 &&
        segments[segments.length - 3] == host &&
        segments[segments.length - 2] == path) {
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

  @override
  String get routeLocation => '/friends/invite/${Uri.encodeComponent(token)}';
}

class GroupInviteDeepLink extends AppDeepLink {
  const GroupInviteDeepLink(this.token);

  final String token;

  @override
  String get routeLocation => '/groups/invite/${Uri.encodeComponent(token)}';
}
