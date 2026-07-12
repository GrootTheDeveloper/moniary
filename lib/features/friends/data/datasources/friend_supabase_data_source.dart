import 'package:supabase_flutter/supabase_flutter.dart';

class FriendSupabaseDataSource {
  const FriendSupabaseDataSource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final rows = await client.rpc('list_friend_profiles');
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchIncomingRequests() async {
    final rows = await client.rpc(
      'list_friend_requests',
      params: {'p_direction': 'incoming'},
    );
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchOutgoingRequests() async {
    final rows = await client.rpc(
      'list_friend_requests',
      params: {'p_direction': 'outgoing'},
    );
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> searchUsers(String usernameQuery) async {
    final rows = await client.rpc(
      'search_friend_profiles',
      params: {'p_query': usernameQuery},
    );
    return _rows(rows);
  }

  Future<Map<String, dynamic>> createInviteLink() async {
    final rows = await client.rpc('create_friend_invite_link');
    return _singleRow(rows);
  }

  Future<Map<String, dynamic>> fetchInvitePreview(String token) async {
    final rows = await client.rpc(
      'get_friend_invite_preview',
      params: {'p_token': token},
    );
    return _singleRow(rows);
  }

  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final rows = await client.rpc(
      'accept_friend_invite',
      params: {'p_token': token},
    );
    return _singleRow(rows);
  }

  Future<void> revokeInviteLink(String token) {
    return client.rpc('revoke_friend_invite_link', params: {'p_token': token});
  }

  Future<void> sendRequest(String username) {
    return client.rpc('send_friend_request', params: {'p_username': username});
  }

  Future<void> sendRequestToUser(String userId) {
    return client.rpc(
      'send_friend_request_by_user_id',
      params: {'p_target_user_id': userId},
    );
  }

  Future<void> acceptRequest(String requestId) {
    return client.rpc(
      'accept_friend_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> declineRequest(String requestId) {
    return client.rpc(
      'decline_friend_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> cancelRequest(String requestId) {
    return client.rpc(
      'cancel_friend_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> removeFriend(String friendUserId) {
    return client.rpc(
      'remove_friend',
      params: {'p_friend_user_id': friendUserId},
    );
  }

  List<Map<String, dynamic>> _rows(dynamic rows) =>
      (rows as List<dynamic>).cast<Map<String, dynamic>>();

  Map<String, dynamic> _singleRow(dynamic rows) {
    if (rows is Map<String, dynamic>) return rows;
    final list = _rows(rows);
    if (list.isEmpty) return const {};
    return list.first;
  }
}
