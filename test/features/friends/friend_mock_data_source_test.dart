import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/friends/data/datasources/friend_mock_data_source.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';

void main() {
  setUp(FriendMockDataSource.resetForTesting);

  FriendMockDataSource source(String userId) =>
      FriendMockDataSource(currentUserId: userId);

  test('search trả profile tối thiểu và không có email field', () async {
    final results = await source('mock-user-id').searchUsers('an_');

    expect(results, hasLength(1));
    expect(results.first.profile.username, 'an_nguyen');
    expect(results.first.profile.fullName, 'An Nguyen');
    expect(results.first.relationStatus, FriendRelationStatus.none);
  });

  test('search không tìm theo tên hiển thị', () async {
    final results = await source('mock-user-id').searchUsers('nguyen');

    expect(results, isEmpty);
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

  test('tạo link kết bạn và receiver xem preview được inviter', () async {
    final creator = source('mock-user-id');
    final receiver = source('mock-friend-1');

    final invite = await creator.createInviteLink();
    final preview = await receiver.fetchInvitePreview(invite.token);

    expect(
      invite.link,
      startsWith('https://go.vuivethoima.id.vn/friends/invite/'),
    );
    expect(preview.status, FriendInviteStatus.active);
    expect(preview.inviter?.userId, 'mock-user-id');
    expect(preview.inviter?.username, 'mock-user');
  });

  test(
    'accept friend invite tạo friendship hai chiều và đánh dấu link used',
    () async {
      final creator = source('mock-user-id');
      final receiver = source('mock-friend-1');
      final invite = await creator.createInviteLink();

      final result = await receiver.acceptInvite(invite.token);

      expect(result.status, FriendInviteAcceptStatus.accepted);
      expect(
        (await creator.fetchFriends()).map((friend) => friend.userId),
        contains('mock-friend-1'),
      );
      expect(
        (await receiver.fetchFriends()).map((friend) => friend.userId),
        contains('mock-user-id'),
      );
      expect(
        (await source('mock-friend-2').fetchInvitePreview(invite.token)).status,
        FriendInviteStatus.used,
      );
    },
  );

  test('không cho dùng link kết bạn của chính mình', () async {
    final creator = source('mock-user-id');
    final invite = await creator.createInviteLink();

    await expectLater(
      creator.acceptInvite(invite.token),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_INVITE_SELF',
        ),
      ),
    );
  });

  test('revoke link khiến receiver không accept được', () async {
    final creator = source('mock-user-id');
    final receiver = source('mock-friend-1');
    final invite = await creator.createInviteLink();

    await creator.revokeInviteLink(invite.token);

    expect(
      (await receiver.fetchInvitePreview(invite.token)).status,
      FriendInviteStatus.revoked,
    );
    await expectLater(
      receiver.acceptInvite(invite.token),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'FRIEND_INVITE_REVOKED',
        ),
      ),
    );
  });
}
