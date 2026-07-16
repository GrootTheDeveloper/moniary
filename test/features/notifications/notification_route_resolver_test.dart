import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/presentation/screens/group_invitations_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_route_paths.dart';
import 'package:moniary/features/notifications/domain/entities/app_notification.dart';
import 'package:moniary/features/notifications/presentation/notification_route_resolver.dart';

void main() {
  test('transaction notification resolves to its exact detail', () {
    final route = NotificationRouteResolver.resolveNotification(
      AppNotification(
        id: 'notification',
        category: AppNotificationCategory.group,
        type: 'transaction_posted',
        isRead: false,
        createdAt: DateTime(2026, 7, 16),
        groupId: 'group-1',
        groupTransactionId: 'transaction-1',
      ),
    );

    expect(
      route,
      GroupRoutePaths.transactionDetail(
        groupId: 'group-1',
        transactionId: 'transaction-1',
      ),
    );
  });

  test('member amount notification resolves to the input workflow', () {
    final route = NotificationRouteResolver.resolvePayload(const {
      'category': 'group',
      'type': 'member_amount_required',
      'group_id': 'group-1',
      'group_transaction_id': 'transaction-1',
    });

    expect(
      route,
      GroupRoutePaths.memberAmount(
        groupId: 'group-1',
        transactionId: 'transaction-1',
      ),
    );
  });

  test('malformed transaction target falls back safely to inbox', () {
    final route = NotificationRouteResolver.resolvePayload(const {
      'category': 'group',
      'type': 'transaction_posted',
      'group_transaction_id': 'transaction-without-group',
    });

    expect(route, '/notifications');
  });

  test('group invite and safe internal action URL are supported', () {
    expect(
      NotificationRouteResolver.resolvePayload(const {'type': 'group_invite'}),
      GroupInvitationsScreen.routePath,
    );
    expect(
      NotificationRouteResolver.resolvePayload(const {
        'type': 'admin_broadcast',
        'action_url': '/budgets',
      }),
      '/budgets',
    );
    expect(
      NotificationRouteResolver.resolvePayload(const {
        'type': 'admin_broadcast',
        'action_url': 'https://malicious.example',
      }),
      '/notifications',
    );
  });
}
