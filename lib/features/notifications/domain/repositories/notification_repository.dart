import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
  });

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();

  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  });

  Future<void> unregisterDevice(String token);
}
