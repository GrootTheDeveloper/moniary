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
