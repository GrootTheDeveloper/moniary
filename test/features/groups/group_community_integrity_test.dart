import 'package:flutter_test/flutter_test.dart';
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
}
