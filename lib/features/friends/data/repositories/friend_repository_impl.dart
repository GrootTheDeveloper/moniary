import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_supabase_data_source.dart';
import '../models/friend_model_mapper.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FriendRepositoryImpl(client);
});

class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl(SupabaseClient client)
    : _client = client,
      _remote = FriendSupabaseDataSource(client);

  final SupabaseClient _client;
  final FriendSupabaseDataSource _remote;

  @override
  String get currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  @override
  Future<List<FriendProfile>> fetchFriends() {
    return _guard('fetch friends', () async {
      return (await _remote.fetchFriends())
          .map(FriendModelMapper.profile)
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendRequest>> fetchIncomingRequests() {
    return _guard('fetch incoming friend requests', () async {
      return (await _remote.fetchIncomingRequests())
          .map((row) => FriendModelMapper.request(row, isIncoming: true))
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendRequest>> fetchOutgoingRequests() {
    return _guard('fetch outgoing friend requests', () async {
      return (await _remote.fetchOutgoingRequests())
          .map((row) => FriendModelMapper.request(row, isIncoming: false))
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendSearchResult>> searchUsers(String usernameQuery) {
    final query = usernameQuery.trim();
    if (query.isEmpty) return Future.value(const []);
    return _guard('search friend profiles', () async {
      return (await _remote.searchUsers(
        query,
      )).map(FriendModelMapper.searchResult).toList(growable: false);
    });
  }

  @override
  Future<FriendInviteLink> createInviteLink() {
    return _guard('create friend invite link', () async {
      return FriendModelMapper.inviteLink(await _remote.createInviteLink());
    });
  }

  @override
  Future<FriendInvitePreview> fetchInvitePreview(String token) {
    return _guard('fetch friend invite preview', () async {
      return FriendModelMapper.invitePreview(
        await _remote.fetchInvitePreview(token.trim()),
      );
    });
  }

  @override
  Future<FriendInviteAcceptResult> acceptInvite(String token) {
    return _guard('accept friend invite', () async {
      return FriendModelMapper.inviteAcceptResult(
        await _remote.acceptInvite(token.trim()),
      );
    });
  }

  @override
  Future<void> revokeInviteLink(String token) {
    return _guard(
      'revoke friend invite link',
      () => _remote.revokeInviteLink(token.trim()),
    );
  }

  @override
  Future<void> sendRequest(String username) {
    return _guard(
      'send friend request',
      () => _remote.sendRequest(username.trim().toLowerCase()),
    );
  }

  @override
  Future<void> sendRequestToUser(String userId) {
    return _guard(
      'send friend request to user',
      () => _remote.sendRequestToUser(userId.trim()),
    );
  }

  @override
  Future<void> acceptRequest(String requestId) {
    return _guard(
      'accept friend request',
      () => _remote.acceptRequest(requestId),
    );
  }

  @override
  Future<void> declineRequest(String requestId) {
    return _guard(
      'decline friend request',
      () => _remote.declineRequest(requestId),
    );
  }

  @override
  Future<void> cancelRequest(String requestId) {
    return _guard(
      'cancel friend request',
      () => _remote.cancelRequest(requestId),
    );
  }

  @override
  Future<void> removeFriend(String friendUserId) {
    return _guard('remove friend', () => _remote.removeFriend(friendUserId));
  }

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(operation, error, stackTrace);
      final message = error.message;
      if (message.startsWith('FRIEND_') || message == 'AUTH_REQUIRED') {
        throw AppException(message, code: message);
      }
      throw AppException(message, code: error.code);
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;
      AppLogger.error(operation, error, stackTrace);
      throw const AppException('errorConnection');
    }
  }
}
