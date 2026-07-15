import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/entities/app_notification.dart';

final notificationCategoryProvider =
    NotifierProvider<NotificationCategoryNotifier, AppNotificationCategory?>(
      NotificationCategoryNotifier.new,
    );

class NotificationCategoryNotifier extends Notifier<AppNotificationCategory?> {
  @override
  AppNotificationCategory? build() => null;

  void setCategory(AppNotificationCategory? category) => state = category;
}

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref
      .watch(notificationRepositoryProvider)
      .fetchNotifications(category: ref.watch(notificationCategoryProvider));
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.when(
    data: (items) => items.where((item) => !item.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final notificationActionControllerProvider =
    AsyncNotifierProvider<NotificationActionController, void>(
      NotificationActionController.new,
    );

class NotificationActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(String notificationId) async {
    await _run(() async {
      await ref.read(notificationRepositoryProvider).markRead(notificationId);
      ref.invalidate(notificationsProvider);
    });
  }

  Future<void> markAllRead() async {
    await _run(() async {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      AppLogger.error('Notification action failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
