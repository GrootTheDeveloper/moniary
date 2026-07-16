import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
    String? groupId,
  });

  Future<void> markRead(String notificationId);

  Future<void> markAllRead({String? groupId});

  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  });

  Future<void> unregisterDevice(String token);
}

abstract interface class AdvancedNotificationRepository {
  Future<NotificationPage> fetchNotificationPage({
    AppNotificationCategory? category,
    String? groupId,
    NotificationCursor? before,
    int limit = 30,
  });

  Future<NotificationUnreadSummary> fetchUnreadSummary({String? groupId});

  Future<void> markNotificationRead(AppNotification notification);

  Future<void> setNotificationReadState(
    AppNotification notification, {
    required bool isRead,
  });
}
