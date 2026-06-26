enum FriendRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  const FriendRequestStatus(this.value);

  final String value;

  static FriendRequestStatus fromValue(String? value) {
    return FriendRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }
}

enum FriendRelationStatus {
  none('none'),
  friends('friends'),
  outgoingPending('outgoing_pending'),
  incomingPending('incoming_pending');

  const FriendRelationStatus(this.value);

  final String value;

  static FriendRelationStatus fromValue(String? value) {
    return FriendRelationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendRelationStatus.none,
    );
  }
}

class FriendProfile {
  const FriendProfile({
    required this.userId,
    this.fullName,
    this.username,
    this.avatarPath,
    this.friendsSince,
  });

  final String userId;
  final String? fullName;
  final String? username;
  final String? avatarPath;
  final DateTime? friendsSince;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return handle;
    return userId;
  }

  String get displayUsername {
    final handle = username?.trim();
    if (handle == null || handle.isEmpty) return '';
    return '@$handle';
  }
}

class FriendSearchResult {
  const FriendSearchResult({
    required this.profile,
    required this.relationStatus,
  });

  final FriendProfile profile;
  final FriendRelationStatus relationStatus;
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.otherUserId,
    required this.status,
    required this.createdAt,
    required this.isIncoming,
    this.fullName,
    this.username,
    this.avatarPath,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String otherUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final bool isIncoming;
  final String? fullName;
  final String? username;
  final String? avatarPath;

  FriendProfile get otherProfile => FriendProfile(
    userId: otherUserId,
    fullName: fullName,
    username: username,
    avatarPath: avatarPath,
  );
}
