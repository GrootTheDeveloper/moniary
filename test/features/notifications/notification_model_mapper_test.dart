import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/notifications/data/models/notification_model_mapper.dart';
import 'package:moniary/features/notifications/domain/entities/app_notification.dart';

void main() {
  test('maps normalized group and personal fields', () {
    final notification = NotificationModelMapper.notification({
      'id': 'notification-1',
      'category': 'personal',
      'type': 'friend_request',
      'group_id': null,
      'group_name': null,
      'group_transaction_id': null,
      'friend_request_id': 'request-1',
      'metadata': {'dedup_key': 'friend_request:request-1'},
      'is_read': false,
      'created_at': '2026-07-14T01:00:00Z',
      'source': 'app',
    });

    expect(notification.category, AppNotificationCategory.personal);
    expect(notification.friendRequestId, 'request-1');
    expect(notification.metadata['dedup_key'], 'friend_request:request-1');
    expect(notification.isRead, isFalse);
  });
}
