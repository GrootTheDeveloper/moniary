enum GroupInviteStatus {
  active,
  accepted,
  used,
  revoked,
  expired,
  invalid,
  alreadyMember,
}

extension GroupInviteStatusValue on GroupInviteStatus {
  String get value => switch (this) {
    GroupInviteStatus.active => 'active',
    GroupInviteStatus.accepted => 'accepted',
    GroupInviteStatus.used => 'used',
    GroupInviteStatus.revoked => 'revoked',
    GroupInviteStatus.expired => 'expired',
    GroupInviteStatus.invalid => 'invalid',
    GroupInviteStatus.alreadyMember => 'already_member',
  };

  static GroupInviteStatus fromValue(String? value) {
    return GroupInviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GroupInviteStatus.invalid,
    );
  }
}

class GroupInvitePreview {
  const GroupInvitePreview({
    required this.status,
    this.groupId,
    this.groupName,
    this.groupAvatarPath,
    this.inviterName,
    this.expiresAt,
  });

  final GroupInviteStatus status;
  final String? groupId;
  final String? groupName;
  final String? groupAvatarPath;
  final String? inviterName;
  final DateTime? expiresAt;

  bool get canAccept => status == GroupInviteStatus.active;
}

class GroupInviteAcceptResult {
  const GroupInviteAcceptResult({required this.status, required this.groupId});

  final GroupInviteStatus status;
  final String groupId;
}
