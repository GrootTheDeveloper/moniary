import 'group_transaction.dart';

class GroupNotificationPreference {
  const GroupNotificationPreference({
    required this.groupId,
    required this.muteAll,
    required this.transactionNotifications,
    required this.debtNotifications,
    required this.inviteNotifications,
    required this.mentionNotifications,
    this.communityComments = true,
    this.communityReactions = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final String groupId;
  final bool muteAll;
  final bool transactionNotifications;
  final bool debtNotifications;
  final bool inviteNotifications;
  final bool mentionNotifications;
  final bool communityComments;
  final bool communityReactions;
  final int? quietHoursStart;
  final int? quietHoursEnd;

  GroupNotificationPreference copyWith({
    bool? muteAll,
    bool? transactionNotifications,
    bool? debtNotifications,
    bool? inviteNotifications,
    bool? mentionNotifications,
    bool? communityComments,
    bool? communityReactions,
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
      communityComments: communityComments ?? this.communityComments,
      communityReactions: communityReactions ?? this.communityReactions,
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

class GroupReactionSummary {
  const GroupReactionSummary({
    required this.emoji,
    required this.count,
    required this.reactedByCurrentUser,
  });

  final String emoji;
  final int count;
  final bool reactedByCurrentUser;
}

class GroupCategorySpending {
  const GroupCategorySpending({
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
  });

  final String categoryName;
  final int totalAmount;
  final int transactionCount;
}

class GroupMemberBreakdown {
  const GroupMemberBreakdown({
    required this.userId,
    required this.displayName,
    required this.shareAmount,
    required this.paidAmount,
    required this.balance,
    required this.transactionCount,
  });

  final String userId;
  final String displayName;
  final int shareAmount;
  final int paidAmount;
  final int balance;
  final int transactionCount;
}

class GroupMonthlyStats {
  const GroupMonthlyStats({
    required this.groupId,
    required this.month,
    required this.totalSpent,
    required this.transactionCount,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.categoryBreakdown,
    required this.memberBreakdown,
  });

  final String groupId;
  final DateTime month;
  final int totalSpent;
  final int transactionCount;
  final String? topCategoryName;
  final int topCategoryAmount;
  final List<GroupCategorySpending> categoryBreakdown;
  final List<GroupMemberBreakdown> memberBreakdown;
}

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

class GroupSettlementHistoryEntry {
  const GroupSettlementHistoryEntry({
    required this.id,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String fromName;
  final String toName;
  final int amount;
  final String status;
  final DateTime updatedAt;
}

class GroupFeedItem {
  const GroupFeedItem({
    required this.transaction,
    required this.reactions,
    required this.commentCount,
  });

  final GroupTransaction transaction;
  final List<GroupReactionSummary> reactions;
  final int commentCount;
}

class GroupPhotoItem {
  const GroupPhotoItem({
    required this.transactionId,
    required this.groupId,
    required this.createdBy,
    required this.caption,
    required this.imagePath,
    required this.amount,
    required this.transactionDate,
    this.creatorName,
  });

  final String transactionId;
  final String groupId;
  final String createdBy;
  final String? caption;
  final String imagePath;
  final int amount;
  final DateTime transactionDate;
  final String? creatorName;
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
    this.autoPost = false,
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
  final bool autoPost;
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
    this.showDescription = false,
    this.showGroupType = false,
    this.showAvatar = false,
    this.slug,
    this.groupName,
    this.avatarPath,
    this.description,
    this.groupType,
    this.memberCount,
    this.transactionCount,
    this.totalSpent,
  });

  final String groupId;
  final bool isEnabled;
  final bool showStats;
  final bool showDescription;
  final bool showGroupType;
  final bool showAvatar;
  final String? slug;
  final String? groupName;
  final String? avatarPath;
  final String? description;
  final String? groupType;
  final int? memberCount;
  final int? transactionCount;
  final int? totalSpent;

  GroupPublicProfile copyWith({
    bool? isEnabled,
    bool? showStats,
    bool? showDescription,
    bool? showGroupType,
    bool? showAvatar,
    String? slug,
    bool clearSlug = false,
    String? groupName,
    String? avatarPath,
    String? description,
    String? groupType,
    int? memberCount,
    int? transactionCount,
    int? totalSpent,
  }) {
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: isEnabled ?? this.isEnabled,
      showStats: showStats ?? this.showStats,
      showDescription: showDescription ?? this.showDescription,
      showGroupType: showGroupType ?? this.showGroupType,
      showAvatar: showAvatar ?? this.showAvatar,
      slug: clearSlug ? null : slug ?? this.slug,
      groupName: groupName ?? this.groupName,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      memberCount: memberCount ?? this.memberCount,
      transactionCount: transactionCount ?? this.transactionCount,
      totalSpent: totalSpent ?? this.totalSpent,
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
