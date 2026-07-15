import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_mock_data_source.dart';
import '../datasources/notification_supabase_data_source.dart';
import '../models/notification_model_mapper.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final useMock = ref.watch(useMockDataModeProvider);
  final userId = ref.watch(currentSessionProvider)?.user.id ?? 'mock-user-id';
  if (useMock || !AppConstants.hasSupabaseConfig) {
    return MockNotificationRepository(
      NotificationMockDataSource(currentUserId: userId),
    );
  }
  return SupabaseNotificationRepository(
    NotificationSupabaseDataSource(ref.watch(supabaseClientProvider)),
  );
});

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._dataSource);

  final NotificationSupabaseDataSource _dataSource;

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
  }) async {
    try {
      final rows = await _dataSource.fetchNotifications(
        category: category?.value,
      );
      return rows.map(NotificationModelMapper.notification).toList();
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load notifications', error, stackTrace);
      throw const AppException(
        'Failed to load notifications',
        code: 'NOTIFICATIONS_READ_ERROR',
      );
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      await _dataSource.markRead(notificationId);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to mark notification read', error, stackTrace);
      throw const AppException(
        'Failed to mark notification read',
        code: 'NOTIFICATION_READ_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dataSource.markAllRead();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to mark all notifications read',
        error,
        stackTrace,
      );
      throw const AppException(
        'Failed to mark all notifications read',
        code: 'NOTIFICATIONS_READ_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  }) {
    return _dataSource.registerDevice(
      token: token,
      platform: platform,
      locale: locale,
      timezone: timezone,
    );
  }

  @override
  Future<void> unregisterDevice(String token) {
    return _dataSource.unregisterDevice(token);
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._dataSource);

  final NotificationMockDataSource _dataSource;

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
  }) {
    return _dataSource.fetchNotifications(category: category);
  }

  @override
  Future<void> markRead(String notificationId) =>
      _dataSource.markRead(notificationId);

  @override
  Future<void> markAllRead() => _dataSource.markAllRead();

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
