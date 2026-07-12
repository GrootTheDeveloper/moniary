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
}
