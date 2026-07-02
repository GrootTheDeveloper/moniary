import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/friend_profile.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_mock_data_source.dart';
import '../datasources/friend_supabase_data_source.dart';
import '../models/friend_model_mapper.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final useMockData =
      ref.watch(useMockDataModeProvider) || !AppConstants.hasSupabaseConfig;
  final currentUserId = ref.watch(currentSessionProvider)?.user.id ?? '';
  return FriendRepositoryImpl(
    client,
    useMockData: useMockData,
    mockDataSource: FriendMockDataSource(currentUserId: currentUserId),
  );
});

class FriendRepositoryImpl implements FriendRepository {
  FriendRepositoryImpl(
    SupabaseClient client, {
    required bool useMockData,
    required FriendMockDataSource mockDataSource,
  }) : _client = client,
       _useMockData = useMockData,
       _mock = mockDataSource,
       _remote = FriendSupabaseDataSource(client);

  final SupabaseClient _client;
  final bool _useMockData;
  final FriendMockDataSource _mock;
  final FriendSupabaseDataSource _remote;

  @override
  String get currentUserId {
    if (_useMockData) return _mock.currentUserId;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  @override
  Future<List<FriendProfile>> fetchFriends() {
    if (_useMockData) return _mock.fetchFriends();
    return _guard('fetch friends', () async {
      return (await _remote.fetchFriends())
          .map(FriendModelMapper.profile)
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendRequest>> fetchIncomingRequests() {
    if (_useMockData) return _mock.fetchIncomingRequests();
    return _guard('fetch incoming friend requests', () async {
      return (await _remote.fetchIncomingRequests())
          .map((row) => FriendModelMapper.request(row, isIncoming: true))
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendRequest>> fetchOutgoingRequests() {
    if (_useMockData) return _mock.fetchOutgoingRequests();
    return _guard('fetch outgoing friend requests', () async {
      return (await _remote.fetchOutgoingRequests())
          .map((row) => FriendModelMapper.request(row, isIncoming: false))
          .toList(growable: false);
    });
  }

  @override
  Future<List<FriendSearchResult>> searchUsers(String usernameQuery) {
    final query = _normalizeSearchQuery(usernameQuery);
    if (query.isEmpty) return Future.value(const []);
    if (_useMockData) return _mock.searchUsers(query);
    return _guard('search friend profiles', () async {
      return (await _remote.searchUsers(
        query,
      )).map(FriendModelMapper.searchResult).toList(growable: false);
    });
  }

  @override
  Future<FriendInviteLink> createInviteLink() {
    if (_useMockData) return _mock.createInviteLink();
    return _guard('create friend invite link', () async {
      return FriendModelMapper.inviteLink(await _remote.createInviteLink());
    });
  }

  @override
  Future<FriendInvitePreview> fetchInvitePreview(String token) {
    if (_useMockData) return _mock.fetchInvitePreview(token);
    return _guard('fetch friend invite preview', () async {
      return FriendModelMapper.invitePreview(
        await _remote.fetchInvitePreview(token.trim()),
      );
    });
  }

  @override
  Future<FriendInviteAcceptResult> acceptInvite(String token) {
    if (_useMockData) return _mock.acceptInvite(token);
    return _guard('accept friend invite', () async {
      return FriendModelMapper.inviteAcceptResult(
        await _remote.acceptInvite(token.trim()),
      );
    });
  }

  @override
  Future<void> revokeInviteLink(String token) {
    if (_useMockData) return _mock.revokeInviteLink(token);
    return _guard(
      'revoke friend invite link',
      () => _remote.revokeInviteLink(token.trim()),
    );
  }

  @override
  Future<void> sendRequestToUser(String targetUserId) {
    final userId = targetUserId.trim();
    if (userId.isEmpty) {
      throw const AppException(
        'Friend user not found',
        code: 'FRIEND_USER_NOT_FOUND',
      );
    }
    if (_useMockData) return _mock.sendRequestToUser(userId);
    return _guard(
      'send friend request',
      () => _remote.sendRequestToUser(userId),
    );
  }

  @override
  Future<void> acceptRequest(String requestId) {
    if (_useMockData) return _mock.acceptRequest(requestId);
    return _guard(
      'accept friend request',
      () => _remote.acceptRequest(requestId),
    );
  }

  @override
  Future<void> declineRequest(String requestId) {
    if (_useMockData) return _mock.declineRequest(requestId);
    return _guard(
      'decline friend request',
      () => _remote.declineRequest(requestId),
    );
  }

  @override
  Future<void> cancelRequest(String requestId) {
    if (_useMockData) return _mock.cancelRequest(requestId);
    return _guard(
      'cancel friend request',
      () => _remote.cancelRequest(requestId),
    );
  }

  @override
  Future<void> removeFriend(String friendUserId) {
    if (_useMockData) return _mock.removeFriend(friendUserId);
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

  String _normalizeSearchQuery(String value) {
    final query = value.trim().toLowerCase();
    return query.startsWith('@') ? query.substring(1).trim() : query;
  }
}
