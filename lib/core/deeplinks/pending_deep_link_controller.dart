import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingDeepLinkProvider =
    NotifierProvider<PendingDeepLinkController, String?>(
      PendingDeepLinkController.new,
    );

final pendingFriendInvitePromptProvider =
    NotifierProvider<PendingFriendInvitePromptController, String?>(
      PendingFriendInvitePromptController.new,
    );

class PendingDeepLinkController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String routeLocation) {
    state = routeLocation;
  }

  String? consume() {
    final routeLocation = state;
    state = null;
    return routeLocation;
  }
}

class PendingFriendInvitePromptController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String token) {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    state = normalized;
  }

  void clear() {
    state = null;
  }
}

String? friendInviteTokenFromRouteLocation(String? routeLocation) {
  if (routeLocation == null || routeLocation.trim().isEmpty) return null;
  final uri = Uri.tryParse(routeLocation.trim());
  if (uri == null) return null;
  final segments = uri.pathSegments;
  if (segments.length == 3 &&
      segments[0] == 'friends' &&
      segments[1] == 'invite') {
    final token = Uri.decodeComponent(segments[2]).trim();
    return token.isEmpty ? null : token;
  }
  return null;
}
