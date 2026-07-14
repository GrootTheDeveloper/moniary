import '../../domain/entities/app_notification.dart';

class NotificationModelMapper {
  static AppNotification notification(Map<String, dynamic> row) {
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : const <String, dynamic>{};

    return AppNotification(
      id: row['id'] as String,
      category: AppNotificationCategory.fromValue(row['category'] as String?),
      type: row['type'] as String? ?? 'generic',
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      groupId: row['group_id'] as String?,
      groupName: row['group_name'] as String?,
      groupTransactionId: row['group_transaction_id'] as String?,
      friendRequestId: row['friend_request_id'] as String?,
      metadata: metadata,
      source: row['source'] as String? ?? 'app',
    );
  }
}
