import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationMockRepositoryProvider = Provider<NotificationRepository>(
  (_) => NotificationMockRepository(),
);

class NotificationMockRepository
    implements NotificationRepository, AdvancedNotificationRepository {
  NotificationMockRepository({List<AppNotification>? seed})
    : _items = seed ?? _demoNotifications();

  List<AppNotification> _items;

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
    String? groupId,
  }) async {
    return _items
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (groupId == null || item.groupId == groupId),
        )
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<NotificationPage> fetchNotificationPage({
    AppNotificationCategory? category,
    String? groupId,
    DateTime? before,
    int limit = 30,
  }) async {
    final all = await fetchNotifications(category: category, groupId: groupId);
    final filtered = before == null
        ? all
        : all.where((item) => item.createdAt.isBefore(before)).toList();
    final items = filtered.take(limit).toList(growable: false);
    return NotificationPage(
      items: items,
      nextCursor: items.isEmpty ? null : items.last.createdAt,
      hasMore: filtered.length > items.length,
    );
  }

  @override
  Future<NotificationUnreadSummary> fetchUnreadSummary({
    String? groupId,
  }) async {
    return NotificationUnreadSummary.fromNotifications(
      _items.where((item) => groupId == null || item.groupId == groupId),
    );
  }

  @override
  Future<void> markRead(String notificationId) async {
    _items = _items
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(isRead: true) : item,
        )
        .toList(growable: false);
  }

  @override
  Future<void> markNotificationRead(AppNotification notification) {
    return markRead(notification.id);
  }

  @override
  Future<void> setNotificationReadState(
    AppNotification notification, {
    required bool isRead,
  }) async {
    _items = _items
        .map(
          (item) => item.identity == notification.identity
              ? item.copyWith(isRead: isRead)
              : item,
        )
        .toList(growable: false);
  }

  @override
  Future<void> markAllRead({String? groupId}) async {
    _items = _items
        .map(
          (item) => groupId == null || item.groupId == groupId
              ? item.copyWith(isRead: true)
              : item,
        )
        .toList(growable: false);
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

  static List<AppNotification> _demoNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'mock-friend-request',
        category: AppNotificationCategory.personal,
        type: 'friend_request',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 8)),
        friendRequestId: 'mock-request',
        metadata: const {'actor_name': 'Minh Anh'},
        source: 'mock',
      ),
      AppNotification(
        id: 'mock-group-transaction',
        category: AppNotificationCategory.group,
        type: 'transaction_posted',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
        groupId: 'mock-group-cafe-weekend',
        groupName: 'Nhóm cuối tuần',
        source: 'mock',
      ),
      AppNotification(
        id: 'mock-community-comment',
        category: AppNotificationCategory.community,
        type: 'transaction_commented',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        groupId: 'mock-group-cafe-weekend',
        groupName: 'Nhóm cuối tuần',
        source: 'mock',
      ),
    ];
  }
}
