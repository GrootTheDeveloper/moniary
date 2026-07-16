import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_supabase_data_source.dart';
import '../models/notification_model_mapper.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  ref.watch(currentSessionProvider);
  return SupabaseNotificationRepository(
    NotificationSupabaseDataSource(ref.watch(supabaseClientProvider)),
  );
});

class SupabaseNotificationRepository
    implements NotificationRepository, AdvancedNotificationRepository {
  SupabaseNotificationRepository(this._dataSource);

  final NotificationSupabaseDataSource _dataSource;

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
    String? groupId,
  }) async {
    try {
      final rows = await _dataSource.fetchNotifications(
        category: category?.value,
        groupId: groupId,
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
  Future<NotificationPage> fetchNotificationPage({
    AppNotificationCategory? category,
    String? groupId,
    NotificationCursor? before,
    int limit = 30,
  }) async {
    try {
      final rows = await _dataSource.fetchNotificationPage(
        category: category?.value,
        groupId: groupId,
        before: before,
        limit: limit,
      );
      final items = rows
          .map(NotificationModelMapper.notification)
          .toList(growable: false);
      return NotificationPage(
        items: items,
        nextCursor: items.isEmpty ? null : items.last.cursor,
        hasMore: items.length >= limit,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load notification page', error, stackTrace);
      throw const AppException(
        'Failed to load notifications',
        code: 'NOTIFICATIONS_READ_ERROR',
      );
    }
  }

  @override
  Future<NotificationUnreadSummary> fetchUnreadSummary({
    String? groupId,
  }) async {
    try {
      final row = await _dataSource.fetchUnreadSummary(groupId: groupId);
      if (row == null) {
        return NotificationUnreadSummary.fromNotifications(
          await fetchNotifications(groupId: groupId),
        );
      }
      return NotificationUnreadSummary(
        total: (row['total'] as num?)?.toInt() ?? 0,
        personal: (row['personal'] as num?)?.toInt() ?? 0,
        group: (row['group_count'] as num?)?.toInt() ?? 0,
        community: (row['community'] as num?)?.toInt() ?? 0,
        system: (row['system_count'] as num?)?.toInt() ?? 0,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load unread summary', error, stackTrace);
      throw const AppException(
        'Failed to load notification summary',
        code: 'NOTIFICATION_SUMMARY_READ_ERROR',
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
  Future<void> markNotificationRead(AppNotification notification) async {
    return setNotificationReadState(notification, isRead: true);
  }

  @override
  Future<void> setNotificationReadState(
    AppNotification notification, {
    required bool isRead,
  }) async {
    try {
      await _dataSource.setNotificationReadState(
        notificationId: notification.id,
        source: notification.source,
        isRead: isRead,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update notification read state',
        error,
        stackTrace,
      );
      throw const AppException(
        'Failed to update notification read state',
        code: 'NOTIFICATION_READ_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<void> markAllRead({String? groupId}) async {
    try {
      await _dataSource.markAllRead(groupId: groupId);
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
