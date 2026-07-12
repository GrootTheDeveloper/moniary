import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/domain/entities/group_invite.dart';

void main() {
  setUp(GroupMockDataSource.resetForTesting);

  GroupMockDataSource source(String userId) =>
      GroupMockDataSource(currentUserId: userId);

  Future<String> createInvite() async {
    final owner = source('owner');
    final groupId = await owner.createGroup(name: 'Trip to Da Lat');
    return owner.createInviteLink(groupId);
  }

  String tokenFrom(String link) => Uri.parse(link).pathSegments.last;

  test(
    'shared group invite remains active after multiple users join',
    () async {
      final link = await createInvite();
      final token = tokenFrom(link);
      final firstMember = source('member-1');
      final secondMember = source('member-2');

      expect(
        (await firstMember.fetchInvitePreview(token)).status,
        GroupInviteStatus.active,
      );
      expect(
        (await firstMember.acceptInvite(token)).status,
        GroupInviteStatus.accepted,
      );
      expect(
        (await secondMember.fetchInvitePreview(token)).status,
        GroupInviteStatus.active,
      );
      expect(
        (await secondMember.acceptInvite(token)).status,
        GroupInviteStatus.accepted,
      );
    },
  );

  test('existing member gets already-member status without an error', () async {
    final link = await createInvite();
    final token = tokenFrom(link);
    final member = source('member-1');

    await member.acceptInvite(token);

    expect(
      (await member.fetchInvitePreview(token)).status,
      GroupInviteStatus.alreadyMember,
    );
    expect(
      (await member.acceptInvite(token)).status,
      GroupInviteStatus.alreadyMember,
    );
  });

  test('revoked group invite cannot be accepted', () async {
    final owner = source('owner');
    final groupId = await owner.createGroup(name: 'Trip to Da Lat');
    final link = await owner.createInviteLink(groupId);
    final token = tokenFrom(link);

    await owner.revokeInviteLink(token);

    expect(
      (await source('member-1').fetchInvitePreview(token)).status,
      GroupInviteStatus.revoked,
    );
    await expectLater(
      source('member-1').acceptInvite(token),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_INVITE_REVOKED',
        ),
      ),
    );
  });

  test(
    'direct invite is available later and activates membership on accept',
    () async {
      final owner = source('owner');
      final groupId = await owner.createGroup(name: 'Trip to Da Lat');
      await owner.inviteByUserId(groupId: groupId, userId: 'member-1');

      final member = source('member-1');
      final invites = await member.fetchDirectInvites();
      expect(invites, hasLength(1));
      expect(invites.single.status, GroupDirectInviteStatus.pending);

      final result = await member.acceptDirectInvite(invites.single.id);
      expect(result.status, GroupInviteStatus.accepted);
      expect((await member.fetchGroups()).single.id, groupId);
      expect(
        (await member.fetchDirectInvites()).single.status,
        GroupDirectInviteStatus.accepted,
      );
    },
  );

  test(
    'direct invite can be declined and remains visible as declined',
    () async {
      final owner = source('owner');
      final groupId = await owner.createGroup(name: 'Trip to Da Lat');
      await owner.inviteByUserId(groupId: groupId, userId: 'member-1');

      final member = source('member-1');
      final invite = (await member.fetchDirectInvites()).single;
      await member.declineDirectInvite(invite.id);

      expect((await member.fetchGroups()), isEmpty);
      expect(
        (await member.fetchDirectInvites()).single.status,
        GroupDirectInviteStatus.declined,
      );
    },
  );

  test(
    'direct invite returns already-member after the user joined by link',
    () async {
      final owner = source('owner');
      final groupId = await owner.createGroup(name: 'Trip to Da Lat');
      final link = await owner.createInviteLink(groupId);
      await owner.inviteByUserId(groupId: groupId, userId: 'member-1');

      final member = source('member-1');
      await member.acceptInvite(tokenFrom(link));
      final directInvite = (await member.fetchDirectInvites()).single;

      expect(
        (await member.acceptDirectInvite(directInvite.id)).status,
        GroupInviteStatus.alreadyMember,
      );
    },
  );
}
