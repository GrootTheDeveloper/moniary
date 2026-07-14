enum AppNotificationCategory {
  personal('personal'),
  group('group'),
  community('community'),
  system('system');

  const AppNotificationCategory(this.value);

  final String value;

  static AppNotificationCategory fromValue(String? value) {
    return values.firstWhere(
      (category) => category.value == value,
      orElse: () => AppNotificationCategory.system,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.groupId,
    this.groupName,
    this.groupTransactionId,
    this.friendRequestId,
    this.metadata = const {},
    this.source = 'app',
  });

  final String id;
  final AppNotificationCategory category;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? groupId;
  final String? groupName;
  final String? groupTransactionId;
  final String? friendRequestId;
  final Map<String, dynamic> metadata;
  final String source;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      category: category,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      groupId: groupId,
      groupName: groupName,
      groupTransactionId: groupTransactionId,
      friendRequestId: friendRequestId,
      metadata: metadata,
      source: source,
    );
  }
}
