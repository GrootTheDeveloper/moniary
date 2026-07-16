import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification.dart';

class NotificationSupabaseDataSource {
  NotificationSupabaseDataSource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchNotifications({
    String? category,
    String? groupId,
  }) async {
    if (groupId != null) {
      return fetchNotificationPage(
        category: category,
        groupId: groupId,
        limit: 100,
      );
    }
    final rows = await client.rpc(
      'list_all_notifications',
      params: {'p_category': category},
    );
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchNotificationPage({
    String? category,
    String? groupId,
    NotificationCursor? before,
    required int limit,
  }) async {
    try {
      final rows = await client.rpc(
        'list_all_notifications_v3',
        params: {
          'p_category': category,
          'p_group_id': groupId,
          'p_before_created_at': before?.createdAt.toUtc().toIso8601String(),
          'p_before_source': before?.source,
          'p_before_id': before?.id,
          'p_limit': limit,
        },
      );
      return _rows(rows);
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error)) rethrow;
      try {
        final rows = await client.rpc(
          'list_all_notifications_v2',
          params: {
            'p_category': category,
            'p_group_id': groupId,
            'p_before': before?.createdAt.toUtc().toIso8601String(),
            'p_limit': limit,
          },
        );
        return _rows(rows);
      } on PostgrestException catch (legacyError) {
        if (!_isMissingFunction(legacyError)) rethrow;
        if (before != null) return const [];
        final legacy = await fetchNotifications(category: category);
        return groupId == null
            ? legacy
            : legacy
                  .where((item) => item['group_id'] == groupId)
                  .toList(growable: false);
      }
    }
  }

  Future<Map<String, dynamic>?> fetchUnreadSummary({String? groupId}) async {
    try {
      final rows = _rows(
        await client.rpc(
          'notification_unread_summary',
          params: {'p_group_id': groupId},
        ),
      );
      return rows.isEmpty ? null : rows.first;
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error)) rethrow;
      return null;
    }
  }

  Future<void> markRead(String notificationId) {
    return client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markNotificationRead({
    required String notificationId,
    required String source,
  }) async {
    try {
      await client.rpc(
        'mark_notification_read_v2',
        params: {'p_notification_id': notificationId, 'p_source': source},
      );
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error)) rethrow;
      await markRead(notificationId);
    }
  }

  Future<void> setNotificationReadState({
    required String notificationId,
    required String source,
    required bool isRead,
  }) async {
    try {
      await client.rpc(
        'set_notification_read_state',
        params: {
          'p_notification_id': notificationId,
          'p_source': source,
          'p_is_read': isRead,
        },
      );
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error) || !isRead) rethrow;
      await markNotificationRead(
        notificationId: notificationId,
        source: source,
      );
    }
  }

  Future<void> markAllRead({String? groupId}) async {
    try {
      await client.rpc(
        'mark_all_notifications_read_scoped',
        params: {'p_group_id': groupId},
      );
    } on PostgrestException catch (error) {
      if (!_isMissingFunction(error) || groupId != null) rethrow;
      await client.rpc('mark_all_notifications_read');
    }
  }

  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  }) {
    return client.rpc(
      'register_notification_device',
      params: {
        'p_token': token,
        'p_platform': platform,
        'p_locale': locale,
        'p_timezone': timezone,
      },
    );
  }

  Future<void> unregisterDevice(String token) {
    return client.rpc(
      'unregister_notification_device',
      params: {'p_token': token},
    );
  }

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  bool _isMissingFunction(PostgrestException error) {
    return error.code == 'PGRST202' ||
        error.code == '42883' ||
        error.message.contains('Could not find the function');
  }
}
