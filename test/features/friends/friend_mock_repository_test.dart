import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/friends/data/datasources/friend_mock_data_source.dart';
import 'package:moniary/features/friends/data/repositories/friend_mock_repository.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';

void main() {
  late FriendMockRepository repository;
  late FriendMockInviteState inviteState;

  setUp(() {
    inviteState = FriendMockInviteState();
    repository = FriendMockRepository(
      FriendMockDataSource(
        currentUserId: 'mock-user-id',
        now: () => DateTime(2026, 7, 16),
        inviteState: inviteState,
      ),
    );
  });

  test('mock friends expose balances and shared group counts', () async {
    final friends = await repository.fetchFriends();

    expect(friends, hasLength(2));
    expect(friends.first.sharedGroupCount, greaterThan(0));
    expect(friends.first.currentUserBalance, greaterThan(0));
  });

  test('incoming request can be accepted into a friendship', () async {
    final requests = await repository.fetchIncomingRequests();
    final request = requests.single;

    await repository.acceptRequest(request.id);

    final friends = await repository.fetchFriends();
    expect(
      friends.any((friend) => friend.userId == request.otherUserId),
      isTrue,
    );
    expect(await repository.fetchIncomingRequests(), isEmpty);
  });

  test('outgoing request can be cancelled', () async {
    final requests = await repository.fetchOutgoingRequests();
    await repository.cancelRequest(requests.single.id);

    expect(await repository.fetchOutgoingRequests(), isEmpty);
  });

  test('search returns relation-specific states', () async {
    final results = await repository.searchUsers('phuong');
    expect(results.single.relationStatus, FriendRelationStatus.outgoingPending);

    final incoming = await repository.searchUsers('minh');
    expect(
      incoming.single.relationStatus,
      FriendRelationStatus.incomingPending,
    );

    final friend = await repository.searchUsers('an');
    expect(friend.single.relationStatus, FriendRelationStatus.friends);
  });

  test(
    'invite code is explicit, reusable before acceptance, and one-time after',
    () async {
      final first = await repository.createInviteLink();
      final second = await repository.createInviteLink();
      expect(second.token, first.token);

      final recipient = FriendMockRepository(
        FriendMockDataSource(
          currentUserId: 'mock-recipient-id',
          now: () => DateTime(2026, 7, 16),
          inviteState: inviteState,
        ),
      );
      final preview = await recipient.fetchInvitePreview(first.token);
      expect(preview.status, FriendInviteStatus.active);

      final result = await recipient.acceptInvite(first.token);
      expect(result.status, FriendInviteAcceptStatus.accepted);
      expect(
        (await repository.fetchInvitePreview(first.token)).status,
        FriendInviteStatus.invalid,
      );
    },
  );

  test('invalid request and self-add return domain errors', () async {
    expect(
      () => repository.sendRequestToUser('missing-user'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_USER_NOT_FOUND',
        ),
      ),
    );

    expect(
      () => repository.sendRequestToUser('mock-user-id'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_CANNOT_ADD_SELF',
        ),
      ),
    );
  });
}
