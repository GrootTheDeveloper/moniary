import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/friend_repository_impl.dart';
import '../domain/entities/friend_profile.dart';

final friendsControllerProvider =
    AsyncNotifierProvider<FriendsController, List<FriendProfile>>(
      FriendsController.new,
    );

final incomingFriendRequestsProvider = FutureProvider<List<FriendRequest>>((
  ref,
) {
  return ref.watch(friendRepositoryProvider).fetchIncomingRequests();
});

final outgoingFriendRequestsProvider = FutureProvider<List<FriendRequest>>((
  ref,
) {
  return ref.watch(friendRepositoryProvider).fetchOutgoingRequests();
});

final friendSearchProvider = FutureProvider.autoDispose
    .family<List<FriendSearchResult>, String>((ref, query) {
      return ref.watch(friendRepositoryProvider).searchUsers(query);
    });

final friendInvitePreviewProvider = FutureProvider.autoDispose
    .family<FriendInvitePreview, String>((ref, token) {
      return ref.watch(friendRepositoryProvider).fetchInvitePreview(token);
    });

final friendActionControllerProvider =
    AsyncNotifierProvider<FriendActionController, void>(
      FriendActionController.new,
    );

class FriendsController extends AsyncNotifier<List<FriendProfile>> {
  @override
  Future<List<FriendProfile>> build() {
    return ref.read(friendRepositoryProvider).fetchFriends();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

class FriendActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendRequest(String username) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).sendRequest(username);
      _invalidateFriendState();
    });
  }

  Future<void> sendRequestToUser(String userId) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).sendRequestToUser(userId);
      _invalidateFriendState();
    });
  }

  Future<FriendInviteLink> createInviteLink() {
    return _run(() async {
      return ref.read(friendRepositoryProvider).createInviteLink();
    });
  }

  Future<FriendInviteAcceptResult> acceptInvite(String token) {
    return _run(() async {
      final result = await ref
          .read(friendRepositoryProvider)
          .acceptInvite(token);
      _invalidateFriendState();
      ref.invalidate(friendInvitePreviewProvider(token));
      return result;
    });
  }

  Future<void> revokeInviteLink(String token) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).revokeInviteLink(token);
      ref.invalidate(friendInvitePreviewProvider(token));
    });
  }

  Future<void> acceptRequest(String requestId) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).acceptRequest(requestId);
      _invalidateFriendState();
    });
  }

  Future<void> declineRequest(String requestId) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).declineRequest(requestId);
      _invalidateFriendState();
    });
  }

  Future<void> cancelRequest(String requestId) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).cancelRequest(requestId);
      _invalidateFriendState();
    });
  }

  Future<void> removeFriend(String friendUserId) {
    return _run(() async {
      await ref.read(friendRepositoryProvider).removeFriend(friendUserId);
      _invalidateFriendState();
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      AppLogger.error('Friend action failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateFriendState() {
    ref.invalidate(friendsControllerProvider);
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(outgoingFriendRequestsProvider);
  }
}
