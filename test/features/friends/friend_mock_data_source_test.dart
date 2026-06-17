import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/friends/data/datasources/friend_mock_data_source.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';

void main() {
  setUp(FriendMockDataSource.resetForTesting);

  FriendMockDataSource source(String userId) =>
      FriendMockDataSource(currentUserId: userId);

  test('search trả profile tối thiểu và không có email field', () async {
    final results = await source('mock-user-id').searchUsers('an');

    expect(results, hasLength(1));
    expect(results.first.profile.username, 'an_nguyen');
    expect(results.first.profile.fullName, 'An Nguyen');
    expect(results.first.relationStatus, FriendRelationStatus.none);
  });

  test('không cho tự kết bạn với chính mình', () async {
    final action = source('mock-user-id').sendRequest('mock-user');

    await expectLater(
      action,
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_CANNOT_ADD_SELF',
        ),
      ),
    );
  });

  test('gửi lời mời tạo outgoing và incoming pending', () async {
    final sender = source('mock-user-id');
    final receiver = source('mock-friend-1');

    await sender.sendRequest('an_nguyen');

    final outgoing = await sender.fetchOutgoingRequests();
    final incoming = await receiver.fetchIncomingRequests();

    expect(outgoing, hasLength(1));
    expect(outgoing.first.otherUserId, 'mock-friend-1');
    expect(outgoing.first.status, FriendRequestStatus.pending);
    expect(incoming, hasLength(1));
    expect(incoming.first.otherUserId, 'mock-user-id');
  });

  test('chặn duplicate pending request theo cả hai chiều', () async {
    final sender = source('mock-user-id');
    await sender.sendRequest('an_nguyen');

    await expectLater(
      sender.sendRequest('an_nguyen'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_REQUEST_ALREADY_PENDING',
        ),
      ),
    );

    await expectLater(
      source('mock-friend-1').sendRequest('mock-user'),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_REQUEST_ALREADY_PENDING',
        ),
      ),
    );
  });

  test('accept request tạo friendship hai chiều', () async {
    final sender = source('mock-user-id');
    final receiver = source('mock-friend-1');
    await sender.sendRequest('an_nguyen');
    final request = (await receiver.fetchIncomingRequests()).single;

    await receiver.acceptRequest(request.id);

    final senderFriends = await sender.fetchFriends();
    final receiverFriends = await receiver.fetchFriends();
    expect(
      senderFriends.map((friend) => friend.userId),
      contains('mock-friend-1'),
    );
    expect(
      receiverFriends.map((friend) => friend.userId),
      contains('mock-user-id'),
    );
    expect(await receiver.fetchIncomingRequests(), isEmpty);
  });

  test('decline request không tạo friendship', () async {
    final sender = source('mock-user-id');
    final receiver = source('mock-friend-1');
    await sender.sendRequest('an_nguyen');
    final request = (await receiver.fetchIncomingRequests()).single;

    await receiver.declineRequest(request.id);

    expect(await sender.fetchFriends(), isEmpty);
    expect(await receiver.fetchFriends(), isEmpty);
    expect(await receiver.fetchIncomingRequests(), isEmpty);
  });

  test('cancel outgoing request xóa trạng thái pending', () async {
    final sender = source('mock-user-id');
    final receiver = source('mock-friend-1');
    await sender.sendRequest('an_nguyen');
    final request = (await sender.fetchOutgoingRequests()).single;

    await sender.cancelRequest(request.id);

    expect(await sender.fetchOutgoingRequests(), isEmpty);
    expect(await receiver.fetchIncomingRequests(), isEmpty);
  });

  test('remove friend xóa friendship hai chiều', () async {
    final sender = source('mock-user-id');
    final receiver = source('mock-friend-1');
    await sender.sendRequest('an_nguyen');
    final request = (await receiver.fetchIncomingRequests()).single;
    await receiver.acceptRequest(request.id);

    await sender.removeFriend('mock-friend-1');

    expect(await sender.fetchFriends(), isEmpty);
    expect(await receiver.fetchFriends(), isEmpty);
  });
}
