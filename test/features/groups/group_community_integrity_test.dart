import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/group_transaction.dart';

void main() {
  setUp(GroupMockDataSource.resetForTesting);

  String tokenFrom(String link) => Uri.parse(link).pathSegments.last;

  test(
    'exact participant split preserves integer financial integrity',
    () async {
      final owner = GroupMockDataSource(currentUserId: 'owner');
      final member = GroupMockDataSource(currentUserId: 'member');
      final groupId = await owner.createGroup(name: 'Trip');
      final invite = await owner.createInviteLink(groupId);
      await member.acceptInvite(tokenFrom(invite));

      final transactionId = await owner.createTransaction(
        GroupTransactionDraft(
          groupId: groupId,
          totalAmount: 301,
          splitMode: GroupSplitMode.exact,
          paymentMode: GroupPaymentMode.singlePayer,
          payerAmounts: const {'owner': 301},
          participantIds: const ['owner', 'member'],
          shareAmounts: const {'owner': 100, 'member': 201},
        ),
      );

      final detail = await member.fetchTransactionDetail(transactionId);
      expect(
        detail.shares
            .map((share) => share.shareAmount)
            .fold<int>(0, (a, b) => a + b),
        301,
      );
      expect(detail.transaction.splitStatus, GroupSplitStatus.posted);
    },
  );

  test(
    'ownership transfer and settled member removal update membership',
    () async {
      final owner = GroupMockDataSource(currentUserId: 'owner');
      final member = GroupMockDataSource(currentUserId: 'member');
      final groupId = await owner.createGroup(name: 'Home');
      final invite = await owner.createInviteLink(groupId);
      await member.acceptInvite(tokenFrom(invite));

      await owner.transferOwnership(groupId: groupId, newOwnerUserId: 'member');
      expect(
        (await member.fetchGroupDetail(groupId)).currentUserRole,
        GroupRole.owner,
      );

      await member.removeMember(groupId: groupId, userId: 'owner');
      final removed = (await member.fetchGroupDetail(
        groupId,
      )).members.singleWhere((item) => item.userId == 'owner');
      expect(removed.status, GroupMemberStatus.removed);
    },
  );

  test('settlement participant can dispute with a reason', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final member = GroupMockDataSource(currentUserId: 'member');
    final groupId = await owner.createGroup(name: 'Dinner');
    final invite = await owner.createInviteLink(groupId);
    await member.acceptInvite(tokenFrom(invite));
    await owner.createTransaction(
      GroupTransactionDraft(
        groupId: groupId,
        totalAmount: 200,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.singlePayer,
        payerAmounts: const {'owner': 200},
        participantIds: const ['owner', 'member'],
      ),
    );

    final settlement = (await member.fetchSettlementOverview(
      groupId,
    )).suggestions.single;
    await member.disputeSettlement(
      settlementId: settlement.id,
      reason: 'Amount needs review',
    );

    final updated = (await member.fetchSettlementOverview(
      groupId,
    )).suggestions.single;
    expect(updated.status, GroupSettlementStatus.disputed);
  });

  test('member cannot leave while their group balance is unresolved', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final member = GroupMockDataSource(currentUserId: 'member');
    final groupId = await owner.createGroup(name: 'Shared home');
    final invite = await owner.createInviteLink(groupId);
    await member.acceptInvite(tokenFrom(invite));
    await owner.createTransaction(
      GroupTransactionDraft(
        groupId: groupId,
        totalAmount: 200,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.singlePayer,
        payerAmounts: const {'owner': 200},
        participantIds: const ['owner', 'member'],
      ),
    );

    expect(
      () => member.leaveGroup(groupId),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_LEAVE_UNRESOLVED',
        ),
      ),
    );
    expect(
      (await member.fetchGroupDetail(groupId)).activeMembers,
      hasLength(2),
    );
  });

  test('a clean member leave is visible to the remaining members', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final member = GroupMockDataSource(currentUserId: 'member');
    final groupId = await owner.createGroup(name: 'Weekend trip');
    final invite = await owner.createInviteLink(groupId);
    await member.acceptInvite(tokenFrom(invite));

    await member.leaveGroup(groupId);

    expect(
      () => member.fetchGroupDetail(groupId),
      throwsA(
        isA<AppException>().having((error) => error.code, 'code', 'NOT_FOUND'),
      ),
    );
    expect(
      (await owner.fetchNotifications()).any(
        (notification) =>
            notification.groupId == groupId &&
            notification.type == 'member_left',
      ),
      isTrue,
    );
  });
}
