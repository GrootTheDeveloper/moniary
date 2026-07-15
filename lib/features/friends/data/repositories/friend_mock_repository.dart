import '../../domain/entities/friend_profile.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_mock_data_source.dart';

class FriendMockRepository implements FriendRepository {
  FriendMockRepository(this._source);

  final FriendMockDataSource _source;

  @override
  String get currentUserId => _source.currentUserId;

  @override
  Future<List<FriendProfile>> fetchFriends() async => _source.fetchFriends();

  @override
  Future<List<FriendRequest>> fetchIncomingRequests() async =>
      _source.fetchIncomingRequests();

  @override
  Future<List<FriendRequest>> fetchOutgoingRequests() async =>
      _source.fetchOutgoingRequests();

  @override
  Future<List<FriendSearchResult>> searchUsers(String usernameQuery) async =>
      _source.searchUsers(usernameQuery);

  @override
  Future<FriendInviteLink> createInviteLink() async =>
      _source.createInviteLink();

  @override
  Future<FriendInvitePreview> fetchInvitePreview(String token) async =>
      _source.fetchInvitePreview(token);

  @override
  Future<FriendInviteAcceptResult> acceptInvite(String token) async =>
      _source.acceptInvite(token);

  @override
  Future<void> revokeInviteLink(String token) async =>
      _source.revokeInviteLink(token);

  @override
  Future<void> sendRequest(String username) async =>
      _source.sendRequest(username);

  @override
  Future<void> sendRequestToUser(String userId) async =>
      _source.sendRequestToUser(userId);

  @override
  Future<void> acceptRequest(String requestId) async =>
      _source.acceptRequest(requestId);

  @override
  Future<void> declineRequest(String requestId) async =>
      _source.declineRequest(requestId);

  @override
  Future<void> cancelRequest(String requestId) async =>
      _source.cancelRequest(requestId);

  @override
  Future<void> removeFriend(String friendUserId) async =>
      _source.removeFriend(friendUserId);
}
