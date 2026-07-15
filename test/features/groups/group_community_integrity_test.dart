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

  test('settlement lifecycle completes and clears the group balance', () async {
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
    await member.markSettlementPaid(settlement.id);
    expect(
      (await owner.fetchSettlementOverview(groupId)).suggestions.single.status,
      GroupSettlementStatus.payerMarkedPaid,
    );

    await owner.confirmSettlementReceived(settlement.id);
    final overview = await member.fetchSettlementOverview(groupId);
    expect(overview.suggestions.single.status, GroupSettlementStatus.completed);
    expect(overview.balances.map((item) => item.balance), everyElement(0));
  });

  test(
    'disputed settlement is reserved and can be reopened by an admin',
    () async {
      final owner = GroupMockDataSource(currentUserId: 'owner');
      final member = GroupMockDataSource(currentUserId: 'member');
      final groupId = await owner.createGroup(name: 'Dinner');
      final invite = await owner.createInviteLink(groupId);
      await member.acceptInvite(tokenFrom(invite));
      final draft = GroupTransactionDraft(
        groupId: groupId,
        totalAmount: 200,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.singlePayer,
        payerAmounts: const {'owner': 200},
        participantIds: const ['owner', 'member'],
      );
      await owner.createTransaction(draft);

      final disputed = (await member.fetchSettlementOverview(
        groupId,
      )).suggestions.single;
      await member.disputeSettlement(
        settlementId: disputed.id,
        reason: 'Please review the amount',
      );
      final disputedSnapshot = (await member.fetchSettlementOverview(
        groupId,
      )).suggestions.single;
      expect(disputedSnapshot.status, GroupSettlementStatus.disputed);
      expect(disputedSnapshot.disputeReason, 'Please review the amount');
      final disputeActivity = (await member.fetchActivities(groupId)).first;
      expect(disputeActivity.type, 'settlement_disputed');
      expect(disputeActivity.metadata['reason'], 'Please review the amount');
      await owner.createTransaction(draft);

      final refreshed = await owner.fetchSettlementOverview(groupId);
      expect(
        refreshed.suggestions.where(
          (item) => item.status == GroupSettlementStatus.disputed,
        ),
        hasLength(1),
      );
      final pending = refreshed.suggestions.where(
        (item) => item.status == GroupSettlementStatus.pending,
      );
      expect(pending, hasLength(1));
      expect(pending.single.amount, 100);

      await owner.resetDisputedSettlement(disputed.id);
      final reopened = await owner.fetchSettlementOverview(groupId);
      expect(
        reopened.suggestions.where(
          (item) => item.status == GroupSettlementStatus.disputed,
        ),
        isEmpty,
      );
      expect(reopened.suggestions, hasLength(1));
      expect(reopened.suggestions.single.status, GroupSettlementStatus.pending);
      expect(reopened.suggestions.single.amount, 200);
      expect(
        (await owner.fetchActivities(groupId)).first.type,
        'settlement_dispute_reset',
      );
    },
  );

  test('posted transactions are locked after settlement starts', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final member = GroupMockDataSource(currentUserId: 'member');
    final groupId = await owner.createGroup(name: 'Dinner');
    final invite = await owner.createInviteLink(groupId);
    await member.acceptInvite(tokenFrom(invite));
    final draft = GroupTransactionDraft(
      groupId: groupId,
      totalAmount: 200,
      splitMode: GroupSplitMode.equal,
      paymentMode: GroupPaymentMode.singlePayer,
      payerAmounts: const {'owner': 200},
      participantIds: const ['owner', 'member'],
    );
    final transactionId = await owner.createTransaction(draft);
    final settlement = (await member.fetchSettlementOverview(
      groupId,
    )).suggestions.single;
    await member.markSettlementPaid(settlement.id);

    expect(
      () => owner.updateTransaction(transactionId: transactionId, draft: draft),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_TRANSACTION_SETTLEMENT_LOCKED',
        ),
      ),
    );
    expect(
      () => owner.deleteTransaction(transactionId),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_TRANSACTION_SETTLEMENT_LOCKED',
        ),
      ),
    );
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

  test('marking all notifications read clears the mock inbox badge', () async {
    final user = GroupMockDataSource(currentUserId: 'mock-user-id');
    await user.fetchGroups();

    final before = await user.fetchNotifications();
    expect(before.any((notification) => !notification.isRead), isTrue);

    await user.markAllNotificationsRead();

    final after = await user.fetchNotifications();
    expect(after.every((notification) => notification.isRead), isTrue);
  });

  test('group admins can edit details and archive a settled group', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final groupId = await owner.createGroup(
      name: 'Weekend plan',
      description: 'Old description',
    );

    await owner.updateGroup(
      groupId: groupId,
      name: 'Weekend reset',
      description: 'New description',
      type: 'trip',
    );
    final updated = await owner.fetchGroupDetail(groupId);
    expect(updated.group.name, 'Weekend reset');
    expect(updated.group.description, 'New description');
    expect(updated.group.type, 'trip');

    await owner.setGroupArchived(groupId: groupId, archived: true);
    expect(
      (await owner.fetchGroupDetail(groupId)).group.status,
      GroupStatus.archived,
    );

    await owner.setGroupArchived(groupId: groupId, archived: false);
    expect(
      (await owner.fetchGroupDetail(groupId)).group.status,
      GroupStatus.active,
    );
  });
}
