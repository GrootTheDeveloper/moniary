import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/friend_profile.dart';

class FriendMockDataSource {
  FriendMockDataSource({required this.currentUserId});

  final String currentUserId;

  static final Map<String, FriendProfile> _directory = {
    'mock-user-id': const FriendProfile(
      userId: 'mock-user-id',
      fullName: 'Mock User',
      username: 'mock-user',
    ),
    'mock-friend-1': const FriendProfile(
      userId: 'mock-friend-1',
      fullName: 'An Nguyen',
      username: 'an_nguyen',
    ),
    'mock-friend-2': const FriendProfile(
      userId: 'mock-friend-2',
      fullName: 'Binh Tran',
      username: 'binh_tran',
    ),
  };

  static final Map<String, Set<String>> _friendships = {};
  static final Map<String, _MockFriendRequest> _requests = {};
  static final Map<String, _MockFriendInvite> _invites = {};
  static var _sequence = 0;

  static void resetForTesting() {
    _friendships.clear();
    _requests.clear();
    _invites.clear();
    _sequence = 0;
  }

  Future<List<FriendProfile>> fetchFriends() async {
    final ids = _friendships[currentUserId] ?? const <String>{};
    final result =
        ids.map((id) => _directory[id]).nonNulls.toList(growable: false)..sort(
          (left, right) => left.displayName.compareTo(right.displayName),
        );
    return result;
  }

  Future<List<FriendRequest>> fetchIncomingRequests() async {
    return _requests.values
        .where(
          (request) =>
              request.toUserId == currentUserId &&
              request.status == FriendRequestStatus.pending,
        )
        .map((request) => request.toEntity(isIncoming: true))
        .toList(growable: false);
  }

  Future<List<FriendRequest>> fetchOutgoingRequests() async {
    return _requests.values
        .where(
          (request) =>
              request.fromUserId == currentUserId &&
              request.status == FriendRequestStatus.pending,
        )
        .map((request) => request.toEntity(isIncoming: false))
        .toList(growable: false);
  }

  Future<List<FriendSearchResult>> searchUsers(String usernameQuery) async {
    final rawQuery = usernameQuery.trim().toLowerCase();
    final query = rawQuery.startsWith('@') ? rawQuery.substring(1) : rawQuery;
    if (query.isEmpty) return const [];
    return _directory.values
        .where(
          (profile) =>
              profile.userId != currentUserId &&
              (profile.username?.toLowerCase().startsWith(query) ?? false),
        )
        .map(
          (profile) => FriendSearchResult(
            profile: profile,
            relationStatus: _relationStatus(profile.userId),
          ),
        )
        .toList(growable: false);
  }

  Future<FriendInviteLink> createInviteLink() async {
    final token = _id('friend-invite-token');
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    _invites[token] = _MockFriendInvite(
      token: token,
      creatorUserId: currentUserId,
      status: FriendInviteStatus.active,
      expiresAt: expiresAt,
    );
    return FriendInviteLink(
      token: token,
      link: AppConstants.friendInviteLink(token),
      expiresAt: expiresAt,
    );
  }

  Future<FriendInvitePreview> fetchInvitePreview(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null) {
      return const FriendInvitePreview(
        status: FriendInviteStatus.invalid,
        relationStatus: FriendRelationStatus.none,
      );
    }
    final inviter = _directory[invite.creatorUserId];
    return FriendInvitePreview(
      status: _inviteStatus(invite),
      relationStatus: _inviteRelationStatus(invite.creatorUserId),
      inviter: inviter,
      expiresAt: invite.expiresAt,
    );
  }

  Future<FriendInviteAcceptResult> acceptInvite(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null) {
      throw const AppException(
        'Friend invite link is invalid',
        code: 'FRIEND_INVITE_INVALID',
      );
    }
    if (invite.creatorUserId == currentUserId) {
      throw const AppException(
        'Cannot use your own friend invite link',
        code: 'FRIEND_INVITE_SELF',
      );
    }
    if (_areFriends(currentUserId, invite.creatorUserId)) {
      return FriendInviteAcceptResult(
        status: FriendInviteAcceptStatus.alreadyFriends,
        inviterUserId: invite.creatorUserId,
      );
    }
    switch (_inviteStatus(invite)) {
      case FriendInviteStatus.active:
        break;
      case FriendInviteStatus.used:
        throw const AppException(
          'Friend invite link already used',
          code: 'FRIEND_INVITE_USED',
        );
      case FriendInviteStatus.revoked:
        throw const AppException(
          'Friend invite link revoked',
          code: 'FRIEND_INVITE_REVOKED',
        );
      case FriendInviteStatus.expired:
        throw const AppException(
          'Friend invite link expired',
          code: 'FRIEND_INVITE_EXPIRED',
        );
      case FriendInviteStatus.invalid:
      case FriendInviteStatus.self:
      case FriendInviteStatus.alreadyFriends:
        throw const AppException(
          'Friend invite link is invalid',
          code: 'FRIEND_INVITE_INVALID',
        );
    }

    for (final request in _requests.values) {
      final samePair =
          (request.fromUserId == currentUserId &&
              request.toUserId == invite.creatorUserId) ||
          (request.fromUserId == invite.creatorUserId &&
              request.toUserId == currentUserId);
      if (samePair && request.status == FriendRequestStatus.pending) {
        request.status = FriendRequestStatus.accepted;
      }
    }
    _friendships.putIfAbsent(currentUserId, () => {}).add(invite.creatorUserId);
    _friendships.putIfAbsent(invite.creatorUserId, () => {}).add(currentUserId);
    invite.status = FriendInviteStatus.used;
    return FriendInviteAcceptResult(
      status: FriendInviteAcceptStatus.accepted,
      inviterUserId: invite.creatorUserId,
    );
  }

  Future<void> revokeInviteLink(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null ||
        invite.creatorUserId != currentUserId ||
        invite.status != FriendInviteStatus.active) {
      throw const AppException(
        'Friend invite link not found',
        code: 'FRIEND_INVITE_NOT_FOUND',
      );
    }
    invite.status = FriendInviteStatus.revoked;
  }

  Future<void> sendRequest(String username) async {
    final rawUsername = username.trim().toLowerCase();
    final normalized = rawUsername.startsWith('@')
        ? rawUsername.substring(1)
        : rawUsername;
    final target = _directory.values.where(
      (profile) => profile.username?.toLowerCase() == normalized,
    );
    if (target.isEmpty) {
      throw const AppException(
        'Friend user not found',
        code: 'FRIEND_USER_NOT_FOUND',
      );
    }
    final targetId = target.first.userId;
    if (targetId == currentUserId) {
      throw const AppException(
        'Cannot add yourself',
        code: 'FRIEND_CANNOT_ADD_SELF',
      );
    }
    if (_areFriends(currentUserId, targetId)) {
      throw const AppException(
        'Already friends',
        code: 'FRIEND_ALREADY_EXISTS',
      );
    }
    if (_hasPendingRequest(currentUserId, targetId)) {
      throw const AppException(
        'Friend request already pending',
        code: 'FRIEND_REQUEST_ALREADY_PENDING',
      );
    }
    final id = _id('friend-request');
    _requests[id] = _MockFriendRequest(
      id: id,
      fromUserId: currentUserId,
      toUserId: targetId,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    final request = _requireRequest(requestId);
    if (request.toUserId != currentUserId ||
        request.status != FriendRequestStatus.pending) {
      throw const AppException(
        'Friend request not found',
        code: 'FRIEND_REQUEST_NOT_FOUND',
      );
    }
    request.status = FriendRequestStatus.accepted;
    _friendships
        .putIfAbsent(request.fromUserId, () => {})
        .add(request.toUserId);
    _friendships
        .putIfAbsent(request.toUserId, () => {})
        .add(request.fromUserId);
  }

  Future<void> declineRequest(String requestId) async {
    final request = _requireRequest(requestId);
    if (request.toUserId != currentUserId ||
        request.status != FriendRequestStatus.pending) {
      throw const AppException(
        'Friend request not found',
        code: 'FRIEND_REQUEST_NOT_FOUND',
      );
    }
    request.status = FriendRequestStatus.declined;
  }

  Future<void> cancelRequest(String requestId) async {
    final request = _requireRequest(requestId);
    if (request.fromUserId != currentUserId ||
        request.status != FriendRequestStatus.pending) {
      throw const AppException(
        'Friend request not found',
        code: 'FRIEND_REQUEST_NOT_FOUND',
      );
    }
    request.status = FriendRequestStatus.cancelled;
  }

  Future<void> removeFriend(String friendUserId) async {
    final removedA = _friendships[currentUserId]?.remove(friendUserId) ?? false;
    final removedB = _friendships[friendUserId]?.remove(currentUserId) ?? false;
    if (!removedA && !removedB) {
      throw const AppException('Friend not found', code: 'FRIEND_NOT_FOUND');
    }
  }

  FriendRelationStatus _relationStatus(String userId) {
    if (_areFriends(currentUserId, userId)) return FriendRelationStatus.friends;
    final pending = _requests.values.where(
      (request) =>
          request.status == FriendRequestStatus.pending &&
          ((request.fromUserId == currentUserId &&
                  request.toUserId == userId) ||
              (request.fromUserId == userId &&
                  request.toUserId == currentUserId)),
    );
    if (pending.isEmpty) return FriendRelationStatus.none;
    return pending.first.fromUserId == currentUserId
        ? FriendRelationStatus.outgoingPending
        : FriendRelationStatus.incomingPending;
  }

  FriendInviteStatus _inviteStatus(_MockFriendInvite invite) {
    if (invite.status != FriendInviteStatus.active) return invite.status;
    if (invite.expiresAt.isBefore(DateTime.now())) {
      return FriendInviteStatus.expired;
    }
    if (invite.creatorUserId == currentUserId) {
      return FriendInviteStatus.self;
    }
    if (_areFriends(currentUserId, invite.creatorUserId)) {
      return FriendInviteStatus.alreadyFriends;
    }
    return FriendInviteStatus.active;
  }

  FriendRelationStatus _inviteRelationStatus(String inviterUserId) {
    if (inviterUserId == currentUserId) return FriendRelationStatus.self;
    return _relationStatus(inviterUserId);
  }

  bool _areFriends(String left, String right) {
    return _friendships[left]?.contains(right) ?? false;
  }

  bool _hasPendingRequest(String left, String right) {
    return _requests.values.any(
      (request) =>
          request.status == FriendRequestStatus.pending &&
          ((request.fromUserId == left && request.toUserId == right) ||
              (request.fromUserId == right && request.toUserId == left)),
    );
  }

  _MockFriendRequest _requireRequest(String requestId) {
    final request = _requests[requestId];
    if (request == null) {
      throw const AppException(
        'Friend request not found',
        code: 'FRIEND_REQUEST_NOT_FOUND',
      );
    }
    return request;
  }

  static String _id(String prefix) => '$prefix-${++_sequence}';
}

class _MockFriendRequest {
  _MockFriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest toEntity({required bool isIncoming}) {
    final otherUserId = isIncoming ? fromUserId : toUserId;
    final profile = FriendMockDataSource._directory[otherUserId];
    return FriendRequest(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      otherUserId: otherUserId,
      status: status,
      createdAt: createdAt,
      isIncoming: isIncoming,
      fullName: profile?.fullName,
      username: profile?.username,
      avatarPath: profile?.avatarPath,
    );
  }
}

class _MockFriendInvite {
  _MockFriendInvite({
    required this.token,
    required this.creatorUserId,
    required this.status,
    required this.expiresAt,
  });

  final String token;
  final String creatorUserId;
  FriendInviteStatus status;
  final DateTime expiresAt;
}
