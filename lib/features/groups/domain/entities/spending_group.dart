import 'group_enums.dart';

class SpendingGroup {
  const SpendingGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.avatarPath,
    this.description,
    this.type,
    this.memberCount = 0,
    this.totalSpent = 0,
    this.currentUserBalance = 0,
    this.hasUnresolvedSettlements = false,
  });

  final String id;
  final String name;
  final String? avatarPath;
  final String? description;
  final String? type;
  final String createdBy;
  final GroupStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final int totalSpent;
  final int currentUserBalance;
  final bool hasUnresolvedSettlements;

  SpendingGroup copyWith({
    String? avatarPath,
    int? memberCount,
    int? totalSpent,
    int? currentUserBalance,
    bool? hasUnresolvedSettlements,
  }) {
    return SpendingGroup(
      id: id,
      name: name,
      avatarPath: avatarPath ?? this.avatarPath,
      description: description,
      type: type,
      createdBy: createdBy,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      memberCount: memberCount ?? this.memberCount,
      totalSpent: totalSpent ?? this.totalSpent,
      currentUserBalance: currentUserBalance ?? this.currentUserBalance,
      hasUnresolvedSettlements:
          hasUnresolvedSettlements ?? this.hasUnresolvedSettlements,
    );
  }
}

class SpendingGroupMember {
  const SpendingGroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.leftAt,
    this.displayName,
    this.username,
    this.avatarPath,
  });

  final String id;
  final String groupId;
  final String userId;
  final GroupRole role;
  final GroupMemberStatus status;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? displayName;
  final String? username;
  final String? avatarPath;

  bool get isActive => status == GroupMemberStatus.active;
  String get resolvedName => displayName?.trim().isNotEmpty == true
      ? displayName!
      : username ?? userId;
}

class SpendingGroupDetail {
  const SpendingGroupDetail({
    required this.group,
    required this.members,
    required this.currentUserRole,
  });

  final SpendingGroup group;
  final List<SpendingGroupMember> members;
  final GroupRole currentUserRole;

  List<SpendingGroupMember> get activeMembers =>
      members.where((member) => member.isActive).toList(growable: false);

  bool get canInvite =>
      currentUserRole == GroupRole.owner || currentUserRole == GroupRole.admin;
}
