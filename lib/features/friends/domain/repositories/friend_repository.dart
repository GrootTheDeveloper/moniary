import '../entities/friend_profile.dart';

abstract interface class FriendRepository {
  String get currentUserId;

  Future<List<FriendProfile>> fetchFriends();

  Future<List<FriendRequest>> fetchIncomingRequests();

  Future<List<FriendRequest>> fetchOutgoingRequests();

  Future<List<FriendSearchResult>> searchUsers(String usernameQuery);

  Future<void> sendRequest(String username);

  Future<void> acceptRequest(String requestId);

  Future<void> declineRequest(String requestId);

  Future<void> cancelRequest(String requestId);

  Future<void> removeFriend(String friendUserId);
}
