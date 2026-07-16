import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/notifications/data/repositories/notification_mock_repository.dart';
import 'package:moniary/features/notifications/domain/entities/app_notification.dart';
import 'package:moniary/features/notifications/domain/repositories/notification_repository.dart';

void main() {
  test('mock inbox supports summary, pagination, and read state', () async {
    final repository = NotificationMockRepository();
    final AdvancedNotificationRepository advanced = repository;

    final firstPage = await advanced.fetchNotificationPage(limit: 2);
    expect(firstPage.items, hasLength(2));
    expect(firstPage.hasMore, isTrue);
    final secondPage = await advanced.fetchNotificationPage(
      limit: 2,
      before: firstPage.nextCursor,
    );
    expect(secondPage.items, isNotEmpty);
    expect(
      secondPage.items
          .map((item) => item.identity)
          .toSet()
          .intersection(firstPage.items.map((item) => item.identity).toSet()),
      isEmpty,
    );
    expect((await advanced.fetchUnreadSummary()).total, 2);

    await advanced.markNotificationRead(firstPage.items.first);
    expect((await advanced.fetchUnreadSummary()).total, 1);

    await advanced.setNotificationReadState(
      firstPage.items.first,
      isRead: false,
    );
    expect((await advanced.fetchUnreadSummary()).total, 2);

    await repository.markAllRead();
    expect((await advanced.fetchUnreadSummary()).total, 0);
  });

  test(
    'group inbox only reads and clears notifications in its group',
    () async {
      final now = DateTime(2026, 7, 16);
      final repository = NotificationMockRepository(
        seed: [
          AppNotification(
            id: 'group-a',
            category: AppNotificationCategory.group,
            type: 'transaction_posted',
            isRead: false,
            createdAt: now,
            groupId: 'group-a',
            source: 'test',
          ),
          AppNotification(
            id: 'group-b',
            category: AppNotificationCategory.community,
            type: 'community_post_commented',
            isRead: false,
            createdAt: now.subtract(const Duration(minutes: 1)),
            groupId: 'group-b',
            source: 'test',
          ),
          AppNotification(
            id: 'personal',
            category: AppNotificationCategory.personal,
            type: 'friend_request',
            isRead: false,
            createdAt: now.subtract(const Duration(minutes: 2)),
            source: 'test',
          ),
        ],
      );
      final AdvancedNotificationRepository advanced = repository;

      expect(
        (await advanced.fetchNotificationPage(groupId: 'group-a')).items,
        hasLength(1),
      );
      expect((await advanced.fetchUnreadSummary(groupId: 'group-a')).total, 1);

      await repository.markAllRead(groupId: 'group-a');

      expect((await advanced.fetchUnreadSummary(groupId: 'group-a')).total, 0);
      expect((await advanced.fetchUnreadSummary()).total, 2);
      expect(
        (await repository.fetchNotifications(groupId: 'group-b')).single.isRead,
        isFalse,
      );
    },
  );
}
