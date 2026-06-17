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

  Future<void> sendRequest(String username) {
    return client.rpc('send_friend_request', params: {'p_username': username});
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
}
