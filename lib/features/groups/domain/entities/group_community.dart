enum GroupInviteStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired'),
  invalid('invalid'),
  alreadyMember('already_member'),
  groupArchived('group_archived');

  const GroupInviteStatus(this.value);

  final String value;

  static GroupInviteStatus fromValue(String? value) {
    return GroupInviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GroupInviteStatus.invalid,
    );
  }
}

enum GroupInviteAcceptStatus {
  accepted('accepted'),
  alreadyMember('already_member');

  const GroupInviteAcceptStatus(this.value);

  final String value;

  static GroupInviteAcceptStatus fromValue(String? value) {
    return GroupInviteAcceptStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GroupInviteAcceptStatus.accepted,
    );
  }
}

class GroupInvitePreview {
  const GroupInvitePreview({
    required this.status,
    required this.memberCount,
    this.groupId,
    this.groupName,
    this.avatarPath,
    this.description,
    this.type,
    this.invitedBy,
    this.inviterName,
    this.expiresAt,
  });

  final GroupInviteStatus status;
  final String? groupId;
  final String? groupName;
  final String? avatarPath;
  final String? description;
  final String? type;
  final String? invitedBy;
  final String? inviterName;
  final int memberCount;
  final DateTime? expiresAt;

  bool get canAccept => status == GroupInviteStatus.pending;
}

class GroupInviteAcceptResult {
  const GroupInviteAcceptResult({required this.status, this.groupId});

  final GroupInviteAcceptStatus status;
  final String? groupId;
}

class GroupNotification {
  const GroupNotification({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.type,
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
