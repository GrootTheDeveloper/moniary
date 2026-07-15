import '../../domain/entities/app_notification.dart';

class NotificationMockDataSource {
  NotificationMockDataSource({required this.currentUserId});

  final String currentUserId;
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'mock-personal-notification',
      category: AppNotificationCategory.personal,
      type: 'friend_request',
      isRead: false,
      createdAt: DateTime(2026, 7, 14, 9),
      friendRequestId: 'mock-friend-request',
    ),
    AppNotification(
      id: 'mock-group-notification',
      category: AppNotificationCategory.group,
      type: 'transaction_posted',
      isRead: false,
      createdAt: DateTime(2026, 7, 13, 18),
      groupId: 'mock-group',
      groupName: 'Demo group',
      groupTransactionId: 'mock-transaction',
      source: 'group',
    ),
    AppNotification(
      id: 'mock-community-notification',
      category: AppNotificationCategory.community,
      type: 'comment_added',
      isRead: true,
      createdAt: DateTime(2026, 7, 12, 12),
      groupId: 'mock-group',
      groupName: 'Demo group',
      groupTransactionId: 'mock-transaction',
      source: 'group',
    ),
  ];

  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final values = _notifications
        .where((item) => item.createdAt.isAfter(cutoff))
        .where((item) => category == null || item.category == category)
        .toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  Future<void> markAllRead() async {
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }
}
