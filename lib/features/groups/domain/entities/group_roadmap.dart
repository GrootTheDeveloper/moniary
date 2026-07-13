class GroupBudget {
  const GroupBudget({
    required this.groupId,
    required this.monthlyLimit,
    required this.warningThresholdPercent,
  });

  final String groupId;
  final int monthlyLimit;
  final int warningThresholdPercent;

  bool get hasLimit => monthlyLimit > 0;

  GroupBudget copyWith({int? monthlyLimit, int? warningThresholdPercent}) {
    return GroupBudget(
      groupId: groupId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      warningThresholdPercent:
          warningThresholdPercent ?? this.warningThresholdPercent,
    );
  }

  static GroupBudget defaults(String groupId) {
    return GroupBudget(
      groupId: groupId,
      monthlyLimit: 0,
      warningThresholdPercent: 80,
    );
  }
}

class GroupNotificationPreference {
  const GroupNotificationPreference({
    required this.groupId,
    required this.muteAll,
    required this.transactionNotifications,
    required this.debtNotifications,
    required this.inviteNotifications,
    required this.mentionNotifications,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final String groupId;
  final bool muteAll;
  final bool transactionNotifications;
  final bool debtNotifications;
  final bool inviteNotifications;
  final bool mentionNotifications;
  final int? quietHoursStart;
  final int? quietHoursEnd;

  GroupNotificationPreference copyWith({
    bool? muteAll,
    bool? transactionNotifications,
    bool? debtNotifications,
    bool? inviteNotifications,
    bool? mentionNotifications,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool clearQuietHours = false,
  }) {
    return GroupNotificationPreference(
      groupId: groupId,
      muteAll: muteAll ?? this.muteAll,
      transactionNotifications:
          transactionNotifications ?? this.transactionNotifications,
      debtNotifications: debtNotifications ?? this.debtNotifications,
      inviteNotifications: inviteNotifications ?? this.inviteNotifications,
      mentionNotifications: mentionNotifications ?? this.mentionNotifications,
      quietHoursStart: clearQuietHours
          ? null
          : quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: clearQuietHours
          ? null
          : quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  static GroupNotificationPreference defaults(String groupId) {
    return GroupNotificationPreference(
      groupId: groupId,
      muteAll: false,
      transactionNotifications: true,
      debtNotifications: true,
      inviteNotifications: true,
      mentionNotifications: true,
    );
  }
}

class GroupRecurringTransaction {
  const GroupRecurringTransaction({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.amount,
    required this.frequency,
    required this.nextRunAt,
    required this.notifyDaysBefore,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final int amount;
  final String frequency;
  final DateTime nextRunAt;
  final int notifyDaysBefore;
  final bool isActive;
  final DateTime createdAt;

  GroupRecurringTransaction copyWith({
    int? amount,
    String? frequency,
    DateTime? nextRunAt,
    int? notifyDaysBefore,
    bool? isActive,
  }) {
    return GroupRecurringTransaction(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      title: title,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  static GroupRecurringTransaction defaults(String groupId, String createdBy) {
    return GroupRecurringTransaction(
      id: '',
      groupId: groupId,
      createdBy: createdBy,
      title: '',
      amount: 0,
      frequency: 'monthly',
      nextRunAt: DateTime.now().add(const Duration(days: 30)),
      notifyDaysBefore: 1,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}

class GroupPublicProfile {
  const GroupPublicProfile({
    required this.groupId,
    required this.isEnabled,
    required this.showStats,
    this.slug,
  });

  final String groupId;
  final bool isEnabled;
  final bool showStats;
  final String? slug;

  GroupPublicProfile copyWith({
    bool? isEnabled,
    bool? showStats,
    String? slug,
  }) {
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: isEnabled ?? this.isEnabled,
      showStats: showStats ?? this.showStats,
      slug: slug ?? this.slug,
    );
  }

  static GroupPublicProfile defaults(String groupId) {
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: false,
      showStats: false,
    );
  }
}
