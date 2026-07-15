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

  String get identity => '$source:$id';

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

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<AppNotification> items;
  final DateTime? nextCursor;
  final bool hasMore;
}

class NotificationUnreadSummary {
  const NotificationUnreadSummary({
    this.total = 0,
    this.personal = 0,
    this.group = 0,
    this.community = 0,
    this.system = 0,
  });

  final int total;
  final int personal;
  final int group;
  final int community;
  final int system;

  int countFor(AppNotificationCategory? category) => switch (category) {
    null => total,
    AppNotificationCategory.personal => personal,
    AppNotificationCategory.group => group,
    AppNotificationCategory.community => community,
    AppNotificationCategory.system => system,
  };

  factory NotificationUnreadSummary.fromNotifications(
    Iterable<AppNotification> notifications,
  ) {
    var personal = 0;
    var group = 0;
    var community = 0;
    var system = 0;
    for (final notification in notifications) {
      if (notification.isRead) continue;
      switch (notification.category) {
        case AppNotificationCategory.personal:
          personal++;
          break;
        case AppNotificationCategory.group:
          group++;
          break;
        case AppNotificationCategory.community:
          community++;
          break;
        case AppNotificationCategory.system:
          system++;
          break;
      }
    }
    return NotificationUnreadSummary(
      total: personal + group + community + system,
      personal: personal,
      group: group,
      community: community,
      system: system,
    );
  }
}
