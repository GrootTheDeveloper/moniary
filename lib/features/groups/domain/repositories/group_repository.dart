import '../entities/group_community.dart';
import '../entities/group_community_feed.dart';
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

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  });

  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  });

  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  });

  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
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

  Future<GroupTransactionPage> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  });

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

  Future<List<GroupActivity>> fetchActivities(String groupId);

  Future<List<GroupCommunityPost>> fetchCommunityPosts({
    required String groupId,
    int offset = 0,
    int limit = 30,
  });

  Future<String> createCommunityPost({
    required String groupId,
    required String type,
    String? content,
    List<GroupCommunityMediaDraft> media = const [],
  });

  Future<void> addCommunityPostComment({
    required String postId,
    required String content,
  });

  Future<void> toggleCommunityPostReaction({
    required String postId,
    required String emoji,
  });

  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId);

  Future<List<GroupPoll>> fetchPolls(String groupId);
  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  });
  Future<void> votePoll({required String pollId, required String optionId});
  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(String groupId);
  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  });

  Future<List<GroupNotification>> fetchNotifications({String? category});

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllNotificationsRead();

  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  );

  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  );

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
    bool autoPost = false,
  });

  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
    bool autoPost = false,
  });

  Future<void> deleteRecurringTransaction(String id);
}
