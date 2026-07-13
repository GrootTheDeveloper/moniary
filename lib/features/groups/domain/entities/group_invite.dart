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

enum GroupDirectInviteStatus {
  pending,
  accepted,
  declined,
  expired,
  revoked,
  invalid,
  alreadyMember,
}

extension GroupDirectInviteStatusValue on GroupDirectInviteStatus {
  String get value => switch (this) {
    GroupDirectInviteStatus.pending => 'pending',
    GroupDirectInviteStatus.accepted => 'accepted',
    GroupDirectInviteStatus.declined => 'declined',
    GroupDirectInviteStatus.expired => 'expired',
    GroupDirectInviteStatus.revoked => 'revoked',
    GroupDirectInviteStatus.invalid => 'invalid',
    GroupDirectInviteStatus.alreadyMember => 'already_member',
  };

  static GroupDirectInviteStatus fromValue(String? value) {
    return GroupDirectInviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GroupDirectInviteStatus.invalid,
    );
  }
}

class GroupDirectInvite {
  const GroupDirectInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.groupAvatarPath,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String inviterName;
  final String? groupAvatarPath;
  final GroupDirectInviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get canRespond => status == GroupDirectInviteStatus.pending;
}
