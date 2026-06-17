import '../entities/group_settlement.dart';
import '../entities/group_transaction.dart';
import '../entities/spending_group.dart';

abstract interface class GroupRepository {
  String get currentUserId;

  Future<List<SpendingGroup>> fetchGroups();

  Future<SpendingGroupDetail> fetchGroupDetail(String groupId);

  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
    String? avatarFilePath,
  });

  Future<String> createInviteLink(String groupId);

  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  });

  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  });

  Future<List<GroupTransaction>> fetchTransactions(String groupId);

  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId);

  Future<String> createTransaction(GroupTransactionDraft draft);

  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  });

  Future<void> deleteTransaction(String transactionId);

  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  });

  Future<GroupSettlementOverview> fetchSettlementOverview(String groupId);

  Future<void> markSettlementPaid(String settlementId);

  Future<void> confirmSettlementReceived(String settlementId);

  Future<void> leaveGroup(String groupId);

  Future<void> addComment({
    required String transactionId,
    required String content,
  });
}
