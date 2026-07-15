import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSupabaseDataSource {
  NotificationSupabaseDataSource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchNotifications({
    String? category,
  }) async {
    final rows = await client.rpc(
      'list_all_notifications',
      params: {'p_category': category},
    );
    return _rows(rows);
  }

  Future<void> markRead(String notificationId) {
    return client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllRead() {
    return client.rpc('mark_all_notifications_read');
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
}
