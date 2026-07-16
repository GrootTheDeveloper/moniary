import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/notifications/application/notification_controller.dart';
import 'package:moniary/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:moniary/features/notifications/domain/entities/app_notification.dart';
import 'package:moniary/features/notifications/domain/repositories/notification_repository.dart';

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository(this.items);

  List<AppNotification> items;

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
    String? groupId,
  }) async {
    return items
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (groupId == null || item.groupId == groupId),
        )
        .toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    items = items
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(isRead: true) : item,
        )
        .toList();
  }

  @override
  Future<void> markAllRead({String? groupId}) async {
    items = items
        .map(
          (item) => groupId == null || item.groupId == groupId
              ? item.copyWith(isRead: true)
              : item,
        )
        .toList();
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  }) async {}

  @override
  Future<void> unregisterDevice(String token) async {}
}

void main() {
  test('composite cursor keeps notifications that share a timestamp', () {
    final timestamp = DateTime.utc(2026, 7, 16, 10);
    final cursor = NotificationCursor(
      createdAt: timestamp,
      source: 'group',
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    );

    expect(
      cursor.containsAfter(
        AppNotification(
          id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          category: AppNotificationCategory.group,
          type: 'transaction_posted',
          isRead: false,
          createdAt: timestamp,
          source: 'group',
        ),
      ),
      isTrue,
    );
    expect(
      cursor.containsAfter(
        AppNotification(
          id: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
          category: AppNotificationCategory.group,
          type: 'transaction_posted',
          isRead: false,
          createdAt: timestamp,
          source: 'group',
        ),
      ),
      isFalse,
    );
  });

  test('unread count is calculated from all categories', () async {
    final repository = _FakeNotificationRepository([
      AppNotification(
        id: 'personal',
        category: AppNotificationCategory.personal,
        type: 'friend_request',
        isRead: false,
        createdAt: DateTime(2026, 7, 14),
      ),
      AppNotification(
        id: 'group',
        category: AppNotificationCategory.group,
        type: 'transaction_posted',
        isRead: false,
        createdAt: DateTime(2026, 7, 14),
      ),
      AppNotification(
        id: 'read',
        category: AppNotificationCategory.community,
        type: 'comment_added',
        isRead: true,
        createdAt: DateTime(2026, 7, 14),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);

    expect(container.read(unreadNotificationCountProvider), 2);
  });

  test('mark all read invalidates the notification query', () async {
    final repository = _FakeNotificationRepository([
      AppNotification(
        id: 'one',
        category: AppNotificationCategory.personal,
        type: 'friend_request',
        isRead: false,
        createdAt: DateTime(2026, 7, 14),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);
    await container
        .read(notificationActionControllerProvider.notifier)
        .markAllRead();
    await container.read(notificationsProvider.future);

    expect(container.read(unreadNotificationCountProvider), 0);
  });

  test('global unread badge is independent from the selected filter', () async {
    final repository = _FakeNotificationRepository([
      AppNotification(
        id: 'personal',
        category: AppNotificationCategory.personal,
        type: 'friend_request',
        isRead: false,
        createdAt: DateTime(2026, 7, 14),
      ),
      AppNotification(
        id: 'group',
        category: AppNotificationCategory.group,
        type: 'transaction_posted',
        isRead: false,
        createdAt: DateTime(2026, 7, 14),
      ),
    ]);
    final container = ProviderContainer(
      overrides: [notificationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(notificationUnreadSummaryProvider.future);
    container
        .read(notificationCategoryProvider.notifier)
        .setCategory(AppNotificationCategory.personal);
    await container.read(notificationsProvider.future);

    expect(container.read(unreadNotificationCountProvider), 2);
    expect(container.read(notificationsProvider).requireValue, hasLength(1));
  });
}
