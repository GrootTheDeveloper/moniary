import '../../friends/presentation/screens/friends_screen.dart';
import '../../groups/presentation/screens/group_invitations_screen.dart';
import '../../groups/presentation/screens/group_route_paths.dart';
import '../domain/entities/app_notification.dart';

abstract final class NotificationRouteResolver {
  const NotificationRouteResolver._();

  static String resolveNotification(AppNotification notification) {
    final actionUrl = _safeInternalRoute(notification.metadata['action_url']);
    if (actionUrl != null) return actionUrl;

    return resolveFields(
      type: notification.type,
      category: notification.category.value,
      groupId: notification.groupId,
      transactionId: notification.groupTransactionId,
      friendRequestId: notification.friendRequestId,
    );
  }

  static String resolvePayload(Map<String, dynamic> payload) {
    final actionUrl = _safeInternalRoute(payload['action_url']);
    if (actionUrl != null) return actionUrl;
    return resolveFields(
      type: _string(payload['type']),
      category: _string(payload['category']),
      groupId: _string(payload['group_id']),
      transactionId: _string(payload['group_transaction_id']),
      friendRequestId: _string(payload['friend_request_id']),
    );
  }

  static String resolveFields({
    String? type,
    String? category,
    String? groupId,
    String? transactionId,
    String? friendRequestId,
  }) {
    if (type == 'group_invite') return GroupInvitationsScreen.routePath;
    if (friendRequestId != null ||
        type == 'friend_request' ||
        type == 'friend_request_accepted') {
      return FriendsScreen.routePath;
    }

    if (groupId != null && transactionId != null) {
      if (type == 'member_amount_required') {
        return GroupRoutePaths.memberAmount(
          groupId: groupId,
          transactionId: transactionId,
        );
      }
      return GroupRoutePaths.transactionDetail(
        groupId: groupId,
        transactionId: transactionId,
      );
    }

    if (groupId != null) {
      if (_settlementTypes.contains(type)) {
        return GroupRoutePaths.settlements(groupId);
      }
      if (_recurringTypes.contains(type)) {
        return GroupRoutePaths.recurring(groupId);
      }
      if (category == AppNotificationCategory.community.value ||
          _communityTypes.contains(type)) {
        return GroupRoutePaths.community(groupId);
      }
      return GroupRoutePaths.home(groupId);
    }

    if (category == AppNotificationCategory.personal.value) {
      return FriendsScreen.routePath;
    }
    return '/notifications';
  }

  static String? _safeInternalRoute(Object? value) {
    final route = _string(value);
    if (route == null || !route.startsWith('/') || route.startsWith('//')) {
      return null;
    }
    final uri = Uri.tryParse(route);
    if (uri == null || uri.hasScheme || uri.host.isNotEmpty) return null;
    return route;
  }

  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static const _settlementTypes = {
    'debt_settled',
    'settlement_marked_paid',
    'settlement_completed',
    'settlement_disputed',
    'settlement_dispute_reset',
  };

  static const _recurringTypes = {'recurring_due', 'recurring_transaction_due'};

  static const _communityTypes = {
    'comment_added',
    'transaction_commented',
    'transaction_reacted',
    'comment_mention',
    'mention',
    'community_post_created',
    'community_post_commented',
    'community_post_reacted',
    'challenge_contribution',
  };
}
