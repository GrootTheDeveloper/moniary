import '../entities/group_community.dart';
import '../entities/group_invite.dart';
import '../entities/group_roadmap.dart';
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

  Future<GroupInvitePreview> fetchInvitePreview(String token);

  Future<GroupInviteAcceptResult> acceptInvite(String token);

  Future<void> revokeInviteLink(String token);

  Future<List<GroupDirectInvite>> fetchDirectInvites();

  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId);

  Future<void> declineDirectInvite(String inviteId);

  Future<void> declineInvite(String token);

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

  Future<GroupStatsOverview> fetchStats(String groupId);

  Future<List<GroupNotification>> fetchNotifications();

  Future<void> markNotificationRead(String notificationId);

  Future<List<GroupActivity>> fetchActivities(String groupId);

  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  );

  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  );

  Future<List<GroupReactionSummary>> fetchReactionSummaries(
    String transactionId,
  );

  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  });

  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  });

  Future<GroupBudget> fetchBudget(String groupId);

  Future<void> updateBudget(GroupBudget budget);

  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  );

  Future<String> buildGroupReportCsv(String groupId);

  Future<List<GroupFeedItem>> fetchFeed(String groupId);

  Future<List<GroupPhotoItem>> fetchPhotoAlbum(String groupId);

  Future<GroupPublicProfile> fetchPublicProfile(String groupId);

  Future<void> updatePublicProfile(GroupPublicProfile profile);

  Future<void> markSettlementPaid(String settlementId);

  Future<void> confirmSettlementReceived(String settlementId);

  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  });

  Future<void> resetDisputedSettlement(String settlementId);

  Future<void> removeMember({required String groupId, required String userId});

  Future<void> leaveGroup(String groupId);

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  });

  Future<void> addComment({
    required String transactionId,
    required String content,
  });

  Future<List<GroupReactionSummary>> fetchReactions(String transactionId);

  Future<void> updateComment({
    required String commentId,
    required String transactionId,
    required String content,
  });

  Future<void> deleteComment({
    required String commentId,
    required String transactionId,
  });

  Future<GroupPublicProfile> fetchPublicGroupProfile(String slug);

  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  );

  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  });

  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
  });

  Future<void> deleteRecurringTransaction(String id);
}
