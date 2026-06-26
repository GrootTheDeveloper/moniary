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
  static var _sequence = 0;

  static void resetForTesting() {
    _friendships.clear();
    _requests.clear();
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
    final query = usernameQuery.trim().toLowerCase();
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

  Future<void> sendRequest(String username) async {
    final normalized = username.trim().toLowerCase();
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
