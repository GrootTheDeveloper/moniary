class GroupNotification {
  const GroupNotification({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.type,
    this.category = 'group',
    required this.isRead,
    required this.createdAt,
    this.groupTransactionId,
    this.inviteToken,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String? groupTransactionId;
  final String? inviteToken;
  final String type;
  final String category;
  final bool isRead;
  final DateTime createdAt;
}

class GroupActivity {
  const GroupActivity({
    required this.id,
    required this.groupId,
    required this.actorUserId,
    required this.type,
    required this.metadata,
    required this.createdAt,
    this.actorName,
  });

  final String id;
  final String groupId;
  final String actorUserId;
  final String? actorName;
  final String type;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

class GroupStatsOverview {
  const GroupStatsOverview({
    required this.totalSpent,
    required this.transactionCount,
    required this.pendingTransactionCount,
    required this.pendingSettlementCount,
    required this.memberCount,
    required this.currentUserBalance,
  });

  final int totalSpent;
  final int transactionCount;
  final int pendingTransactionCount;
  final int pendingSettlementCount;
  final int memberCount;
  final int currentUserBalance;
}

class GroupAuditLog {
  const GroupAuditLog({
    required this.id,
    required this.groupId,
    required this.action,
    required this.createdAt,
    this.actorUserId,
    this.targetUserId,
    this.targetTransactionId,
    this.metadata = const {},
  });

  final String id;
  final String groupId;
  final String? actorUserId;
  final String action;
  final String? targetUserId;
  final String? targetTransactionId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
}

class GroupPollOption {
  const GroupPollOption({
    required this.id,
    required this.label,
    this.voteCount = 0,
  });
  final String id;
  final String label;
  final int voteCount;
}

class GroupPoll {
  const GroupPoll({
    required this.id,
    required this.groupId,
    required this.title,
    required this.options,
    required this.isClosed,
    required this.createdAt,
    this.selectedOptionId,
  });
  final String id;
  final String groupId;
  final String title;
  final List<GroupPollOption> options;
  final bool isClosed;
  final DateTime createdAt;
  final String? selectedOptionId;
}

class GroupSavingsChallenge {
  const GroupSavingsChallenge({
    required this.id,
    required this.groupId,
    required this.title,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
    required this.totalContributed,
    required this.isActive,
  });
  final String id;
  final String groupId;
  final String title;
  final int targetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final int totalContributed;
  final bool isActive;
}
