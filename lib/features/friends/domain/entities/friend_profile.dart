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
  incomingPending('incoming_pending'),
  self('self');

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
    this.sharedGroupCount = 0,
    this.currentUserBalance = 0,
  });

  final String userId;
  final String? fullName;
  final String? username;
  final String? avatarPath;
  final DateTime? friendsSince;
  final int sharedGroupCount;
  final int currentUserBalance;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty && !_isGeneratedUsername(handle)) {
      return handle;
    }
    return userId;
  }

  String get displayUsername {
    final handle = username?.trim();
    if (handle == null || handle.isEmpty || _isGeneratedUsername(handle)) {
      return '';
    }
    return '@$handle';
  }

  bool _isGeneratedUsername(String value) {
    return RegExp(r'^user_[0-9a-f]{24}$').hasMatch(value.trim());
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

enum FriendInviteStatus {
  active('active'),
  used('used'),
  revoked('revoked'),
  expired('expired'),
  invalid('invalid'),
  self('self'),
  alreadyFriends('already_friends');

  const FriendInviteStatus(this.value);

  final String value;

  static FriendInviteStatus fromValue(String? value) {
    return FriendInviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendInviteStatus.invalid,
    );
  }
}

enum FriendInviteAcceptStatus {
  accepted('accepted'),
  alreadyFriends('already_friends');

  const FriendInviteAcceptStatus(this.value);

  final String value;

  static FriendInviteAcceptStatus fromValue(String? value) {
    return FriendInviteAcceptStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendInviteAcceptStatus.accepted,
    );
  }
}

class FriendInviteLink {
  const FriendInviteLink({
    required this.token,
    required this.link,
    required this.expiresAt,
  });

  final String token;
  final String link;
  final DateTime expiresAt;
}

class FriendInvitePreview {
  const FriendInvitePreview({
    required this.status,
    required this.relationStatus,
    this.inviter,
    this.expiresAt,
  });

  final FriendInviteStatus status;
  final FriendRelationStatus relationStatus;
  final FriendProfile? inviter;
  final DateTime? expiresAt;

  /// Whether the viewer is already friends with the inviter.
  ///
  /// The preview RPC can surface this two different ways: through [status]
  /// when the link is still active, or only through [relationStatus] when the
  /// link was already marked `used` at the moment the friendship formed (the
  /// `used` branch is evaluated before `already_friends` server-side). Both
  /// signals must be checked, otherwise a re-opened link between existing
  /// friends looks like a plain "used" or "active" link.
  bool get isAlreadyFriends =>
      status == FriendInviteStatus.alreadyFriends ||
      relationStatus == FriendRelationStatus.friends;

  /// Whether the link belongs to the viewer themselves.
  bool get isSelf =>
      status == FriendInviteStatus.self ||
      relationStatus == FriendRelationStatus.self;

  /// Only a live link pointing at someone who is not yet a friend can be
  /// accepted. Already-friends and self links are terminal, informational
  /// states.
  bool get canAccept =>
      status == FriendInviteStatus.active && !isAlreadyFriends && !isSelf;
}

class FriendInviteAcceptResult {
  const FriendInviteAcceptResult({required this.status, this.inviterUserId});

  final FriendInviteAcceptStatus status;
  final String? inviterUserId;
}
