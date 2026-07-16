import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/friend_profile.dart';

/// In-memory Friend data for local development and guest/demo mode.
///
/// The mock intentionally follows the same request and invite state
/// transitions as the Supabase RPCs so the UI can be exercised without a
/// backend.
class FriendMockDataSource {
  FriendMockDataSource({
    required this.currentUserId,
    DateTime Function()? now,
    FriendMockInviteState? inviteState,
  }) : _now = now ?? DateTime.now,
       _inviteState = inviteState ?? FriendMockInviteState(),
       _friends = [
         FriendProfile(
           userId: 'mock-friend-an',
           fullName: 'An Nguyễn',
           username: 'an_nguyen',
           friendsSince: DateTime(2025, 9, 14),
           sharedGroupCount: 2,
           currentUserBalance: 185000,
         ),
         FriendProfile(
           userId: 'mock-friend-linh',
           fullName: 'Linh Trần',
           username: 'linh_tran',
           friendsSince: DateTime(2025, 11, 2),
           sharedGroupCount: 1,
           currentUserBalance: -42000,
         ),
       ],
       _profiles = [
         const FriendProfile(
           userId: 'mock-user-id',
           fullName: 'Bạn',
           username: 'mock_user',
         ),
         const FriendProfile(
           userId: 'mock-friend-an',
           fullName: 'An Nguyễn',
           username: 'an_nguyen',
         ),
         const FriendProfile(
           userId: 'mock-friend-linh',
           fullName: 'Linh Trần',
           username: 'linh_tran',
         ),
         const FriendProfile(
           userId: 'mock-friend-minh',
           fullName: 'Minh Phạm',
           username: 'minh_pham',
         ),
         const FriendProfile(
           userId: 'mock-friend-phuong',
           fullName: 'Phương Lê',
           username: 'phuong_le',
         ),
         const FriendProfile(
           userId: 'mock-friend-khoa',
           fullName: 'Khoa Đỗ',
           username: 'khoa_do',
         ),
       ],
       _incomingRequests = [
         FriendRequest(
           id: 'mock-request-incoming-1',
           fromUserId: 'mock-friend-minh',
           toUserId: 'mock-user-id',
           otherUserId: 'mock-friend-minh',
           status: FriendRequestStatus.pending,
           createdAt: DateTime(2026, 7, 14),
           isIncoming: true,
           fullName: 'Minh Phạm',
           username: 'minh_pham',
         ),
       ],
       _outgoingRequests = [
         FriendRequest(
           id: 'mock-request-outgoing-1',
           fromUserId: 'mock-user-id',
           toUserId: 'mock-friend-phuong',
           otherUserId: 'mock-friend-phuong',
           status: FriendRequestStatus.pending,
           createdAt: DateTime(2026, 7, 15),
           isIncoming: false,
           fullName: 'Phương Lê',
           username: 'phuong_le',
         ),
       ];

  final String currentUserId;
  final DateTime Function() _now;
  final FriendMockInviteState _inviteState;
  final List<FriendProfile> _friends;
  final List<FriendProfile> _profiles;
  final List<FriendRequest> _incomingRequests;
  final List<FriendRequest> _outgoingRequests;

  var _requestSequence = 10;
  var _inviteSequence = 1;

  List<FriendProfile> fetchFriends() => List.unmodifiable(_friends);

  List<FriendRequest> fetchIncomingRequests() =>
      List.unmodifiable(_incomingRequests);

  List<FriendRequest> fetchOutgoingRequests() =>
      List.unmodifiable(_outgoingRequests);

  List<FriendSearchResult> searchUsers(String rawQuery) {
    var query = rawQuery.trim().toLowerCase();
    if (query.startsWith('@')) query = query.substring(1);
    if (query.isEmpty) return const [];

    return _profiles
        .where((profile) {
          final name = profile.fullName?.toLowerCase() ?? '';
          final username = profile.username?.toLowerCase() ?? '';
          return username.startsWith(query) || name.contains(query);
        })
        .map(
          (profile) => FriendSearchResult(
            profile: profile,
            relationStatus: _relationStatus(profile.userId),
          ),
        )
        .toList(growable: false);
  }

  FriendInviteLink createInviteLink() {
    final now = _now();
    final currentToken = _inviteState.token;
    final currentExpiry = _inviteState.expiresAt;
    if (currentToken != null &&
        currentExpiry != null &&
        currentExpiry.isAfter(now)) {
      return FriendInviteLink(
        token: currentToken,
        link: AppConstants.friendInviteLink(currentToken),
        expiresAt: currentExpiry,
      );
    }

    final token = 'mock-friend-invite-${_inviteSequence++}';
    final expiresAt = now.add(const Duration(days: 30));
    _inviteState
      ..token = token
      ..expiresAt = expiresAt
      ..creatorUserId = currentUserId;
    return FriendInviteLink(
      token: token,
      link: AppConstants.friendInviteLink(token),
      expiresAt: expiresAt,
    );
  }

  FriendInvitePreview fetchInvitePreview(String token) {
    final normalized = token.trim();
    final creatorUserId = _inviteState.creatorUserId;
    final inviter = creatorUserId == null
        ? null
        : _profileForUserId(creatorUserId);
    final expiresAt = _inviteState.expiresAt;
    if (normalized.isEmpty || normalized != _inviteState.token) {
      return const FriendInvitePreview(
        status: FriendInviteStatus.invalid,
        relationStatus: FriendRelationStatus.none,
      );
    }

    final relation = inviter == null
        ? FriendRelationStatus.none
        : _relationStatus(inviter.userId);
    final status = relation == FriendRelationStatus.self
        ? FriendInviteStatus.self
        : relation == FriendRelationStatus.friends
        ? FriendInviteStatus.alreadyFriends
        : expiresAt == null || !expiresAt.isAfter(_now())
        ? FriendInviteStatus.expired
        : FriendInviteStatus.active;
    return FriendInvitePreview(
      status: status,
      relationStatus: relation,
      inviter: inviter,
      expiresAt: expiresAt,
    );
  }

  FriendInviteAcceptResult acceptInvite(String token) {
    final preview = fetchInvitePreview(token);
    if (preview.status == FriendInviteStatus.self) {
      throw const AppException(
        'Cannot accept your own invite',
        code: 'FRIEND_INVITE_SELF',
      );
    }
    if (preview.status == FriendInviteStatus.alreadyFriends) {
      return FriendInviteAcceptResult(
        status: FriendInviteAcceptStatus.alreadyFriends,
        inviterUserId: preview.inviter?.userId,
      );
    }
    if (!preview.canAccept) {
      throw AppException(
        'Friend invite cannot be accepted',
        code: 'FRIEND_INVITE_${preview.status.value.toUpperCase()}',
      );
    }

    _incomingRequests.removeWhere(
      (request) => request.otherUserId == preview.inviter!.userId,
    );
    _outgoingRequests.removeWhere(
      (request) => request.otherUserId == preview.inviter!.userId,
    );
    _addFriend(preview.inviter!);
    _inviteState
      ..token = null
      ..expiresAt = null
      ..creatorUserId = null;
    return FriendInviteAcceptResult(
      status: FriendInviteAcceptStatus.accepted,
      inviterUserId: preview.inviter!.userId,
    );
  }

  void revokeInviteLink(String token) {
    if (token.trim().isEmpty || token.trim() != _inviteState.token) {
      throw const AppException(
        'Friend invite not found',
        code: 'FRIEND_INVITE_NOT_FOUND',
      );
    }
    _inviteState
      ..token = null
      ..expiresAt = null
      ..creatorUserId = null;
  }

  void sendRequest(String username) {
    final normalized = username.trim().toLowerCase();
    final profile = _profiles.firstWhere(
      (candidate) => candidate.username?.toLowerCase() == normalized,
      orElse: () => throw const AppException(
        'Friend user not found',
        code: 'FRIEND_USER_NOT_FOUND',
      ),
    );
    sendRequestToUser(profile.userId);
  }

  void sendRequestToUser(String userId) {
    if (userId == currentUserId) {
      throw const AppException(
        'Cannot add yourself',
        code: 'FRIEND_CANNOT_ADD_SELF',
      );
    }
    final profile = _profileById(userId);
    if (_relationStatus(userId) == FriendRelationStatus.friends) {
      throw const AppException(
        'Already friends',
        code: 'FRIEND_ALREADY_EXISTS',
      );
    }
    if (_relationStatus(userId) != FriendRelationStatus.none) {
      throw const AppException(
        'Friend request already pending',
        code: 'FRIEND_REQUEST_ALREADY_PENDING',
      );
    }
    _outgoingRequests.add(
      FriendRequest(
        id: 'mock-request-outgoing-${_requestSequence++}',
        fromUserId: currentUserId,
        toUserId: profile.userId,
        otherUserId: profile.userId,
        status: FriendRequestStatus.pending,
        createdAt: _now(),
        isIncoming: false,
        fullName: profile.fullName,
        username: profile.username,
        avatarPath: profile.avatarPath,
      ),
    );
  }

  void acceptRequest(String requestId) {
    final index = _incomingRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) _throwRequestNotFound();
    final request = _incomingRequests.removeAt(index);
    _outgoingRequests.removeWhere(
      (candidate) => candidate.otherUserId == request.otherUserId,
    );
    _addFriend(request.otherProfile);
  }

  void declineRequest(String requestId) {
    final index = _incomingRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) _throwRequestNotFound();
    _incomingRequests.removeAt(index);
  }

  void cancelRequest(String requestId) {
    final index = _outgoingRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) _throwRequestNotFound();
    _outgoingRequests.removeAt(index);
  }

  void removeFriend(String friendUserId) {
    final removed = _friends.where((friend) => friend.userId == friendUserId);
    if (removed.isEmpty) {
      throw const AppException('Friend not found', code: 'FRIEND_NOT_FOUND');
    }
    _friends.removeWhere((friend) => friend.userId == friendUserId);
  }

  FriendProfile _profileById(String userId) {
    return _profiles.firstWhere(
      (profile) => profile.userId == userId,
      orElse: () => throw const AppException(
        'Friend user not found',
        code: 'FRIEND_USER_NOT_FOUND',
      ),
    );
  }

  FriendProfile _profileForUserId(String userId) {
    final knownProfile = _profiles.where((profile) => profile.userId == userId);
    if (knownProfile.isNotEmpty) return knownProfile.first;
    return FriendProfile(
      userId: userId,
      fullName: userId == currentUserId ? 'Bạn' : null,
      username: userId == currentUserId ? 'mock_user' : null,
    );
  }

  FriendRelationStatus _relationStatus(String userId) {
    if (userId == currentUserId) return FriendRelationStatus.self;
    if (_friends.any((friend) => friend.userId == userId)) {
      return FriendRelationStatus.friends;
    }
    if (_outgoingRequests.any((request) => request.otherUserId == userId)) {
      return FriendRelationStatus.outgoingPending;
    }
    if (_incomingRequests.any((request) => request.otherUserId == userId)) {
      return FriendRelationStatus.incomingPending;
    }
    return FriendRelationStatus.none;
  }

  void _addFriend(FriendProfile profile) {
    if (_friends.any((friend) => friend.userId == profile.userId)) return;
    _friends.add(
      profile.copyWith(
        friendsSince: _now(),
        sharedGroupCount: profile.sharedGroupCount,
        currentUserBalance: profile.currentUserBalance,
      ),
    );
  }

  void _throwRequestNotFound() {
    throw const AppException(
      'Friend request not found',
      code: 'FRIEND_REQUEST_NOT_FOUND',
    );
  }
}

/// Shared invite state lets tests model a creator and a recipient in Mock Mode
/// while keeping the production repository contract unchanged.
class FriendMockInviteState {
  String? token;
  DateTime? expiresAt;
  String? creatorUserId;
}

extension on FriendProfile {
  FriendProfile copyWith({
    DateTime? friendsSince,
    int? sharedGroupCount,
    int? currentUserBalance,
  }) {
    return FriendProfile(
      userId: userId,
      fullName: fullName,
      username: username,
      avatarPath: avatarPath,
      friendsSince: friendsSince ?? this.friendsSince,
      sharedGroupCount: sharedGroupCount ?? this.sharedGroupCount,
      currentUserBalance: currentUserBalance ?? this.currentUserBalance,
    );
  }
}
