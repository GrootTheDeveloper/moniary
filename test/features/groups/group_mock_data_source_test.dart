import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/domain/entities/group_community.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';

void main() {
  group('GroupMockDataSource', () {
    test(
      'invite by user id creates an actionable invite notification',
      () async {
        const ownerId = 'mock-owner-invite-token';
        const invitedId = 'mock-invited-invite-token';
        final ownerSource = GroupMockDataSource(currentUserId: ownerId);
        final invitedSource = GroupMockDataSource(currentUserId: invitedId);
        final groupId = await ownerSource.createGroup(name: 'Trip');

        await ownerSource.inviteByUserId(groupId: groupId, userId: invitedId);

        final notifications = await invitedSource.fetchNotifications();
        expect(notifications.first.type, 'group_invite');
        expect(notifications.first.inviteToken, isNotNull);

        final result = await invitedSource.acceptInvite(
          notifications.first.inviteToken!,
        );
        expect(result.status, GroupInviteAcceptStatus.accepted);
        expect(result.groupId, groupId);
      },
    );

    test(
      'transfer ownership promotes target and demotes current owner',
      () async {
        const ownerId = 'mock-owner-transfer';
        const nextOwnerId = 'mock-next-owner-transfer';
        final ownerSource = GroupMockDataSource(currentUserId: ownerId);
        final nextOwnerSource = GroupMockDataSource(currentUserId: nextOwnerId);
        final groupId = await ownerSource.createGroup(name: 'House');
        await ownerSource.inviteByUserId(groupId: groupId, userId: nextOwnerId);
        final notifications = await nextOwnerSource.fetchNotifications();
        await nextOwnerSource.acceptInvite(notifications.first.inviteToken!);

        await ownerSource.transferOwnership(
          groupId: groupId,
          newOwnerUserId: nextOwnerId,
        );

        final ownerDetail = await ownerSource.fetchGroupDetail(groupId);
        final nextOwnerDetail = await nextOwnerSource.fetchGroupDetail(groupId);

        expect(ownerDetail.currentUserRole, GroupRole.member);
        expect(nextOwnerDetail.currentUserRole, GroupRole.owner);
      },
    );
  });
}
