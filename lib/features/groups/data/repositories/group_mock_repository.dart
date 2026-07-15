import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_community_feed.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_mock_data_source.dart';

/// Repository boundary for the no-Supabase demo mode.
///
/// The mock data source owns the group business rules. This adapter keeps the
/// production repository unchanged while exposing the newer repository
/// methods used by the current Group UI.
class GroupMockRepository implements GroupRepository {
  GroupMockRepository(this._source);

  final GroupMockDataSource _source;
  final Map<String, GroupBudget> _budgets = {};
  final Map<String, GroupNotificationPreference> _preferences = {};
  final Map<String, GroupPublicProfile> _profiles = {};
  final Map<String, List<GroupRecurringTransaction>> _recurring = {};
  var _recurringSequence = 0;

  @override
  String get currentUserId => _source.currentUserId;

  @override
  Future<List<SpendingGroup>> fetchGroups() => _source.fetchGroups();

  @override
  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) =>
      _source.fetchGroupDetail(groupId);

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
    String? avatarFilePath,
  }) => _source.createGroup(name: name, description: description, type: type);

  @override
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) => _source.updateGroup(
    groupId: groupId,
    name: name,
    description: description,
    type: type,
  );

  @override
  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  }) => _source.updateGroupAvatar(groupId: groupId, filePath: filePath);

  @override
  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) =>
      _source.updateGroupCurrency(groupId: groupId, baseCurrency: baseCurrency);

  @override
  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) => _source.setGroupArchived(groupId: groupId, archived: archived);

  @override
  Future<String> createInviteLink(String groupId) =>
      _source.createInviteLink(groupId);

  @override
  Future<GroupInvitePreview> fetchInvitePreview(String token) =>
      _source.fetchInvitePreview(token);

  @override
  Future<GroupInviteAcceptResult> acceptInvite(String token) =>
      _source.acceptInvite(token);

  @override
  Future<void> revokeInviteLink(String token) =>
      _source.revokeInviteLink(token);

  @override
  Future<List<GroupDirectInvite>> fetchDirectInvites() =>
      _source.fetchDirectInvites();

  @override
  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId) =>
      _source.acceptDirectInvite(inviteId);

  @override
  Future<void> declineDirectInvite(String inviteId) =>
      _source.declineDirectInvite(inviteId);

  @override
  Future<void> declineInvite(String token) async {}

  @override
  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) => _source.inviteByUsername(groupId: groupId, username: username);

  @override
  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) => _source.inviteByUserId(groupId: groupId, userId: userId);

  @override
  Future<List<GroupTransaction>> fetchTransactions(String groupId) =>
      _source.fetchTransactions(groupId);

  @override
  Future<GroupTransactionPage> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async {
    final rows = await _source.fetchTransactionsPage(
      groupId: groupId,
      offset: offset,
      limit: limit,
      query: query,
      status: status,
    );
    return GroupTransactionPage(
      items: rows.take(limit).toList(growable: false),
      hasMore: rows.length > limit,
    );
  }

  @override
  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId) =>
      _source.fetchTransactionDetail(transactionId);

  @override
  Future<String> createTransaction(GroupTransactionDraft draft) =>
      _source.createTransaction(draft);

  @override
  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) => _source.updateTransaction(transactionId: transactionId, draft: draft);

  @override
  Future<void> deleteTransaction(String transactionId) =>
      _source.deleteTransaction(transactionId);

  @override
  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  }) => _source.submitMemberAmount(
    transactionId: transactionId,
    shareAmount: shareAmount,
  );

  @override
  Future<GroupSettlementOverview> fetchSettlementOverview(String groupId) =>
      _source.fetchSettlementOverview(groupId);

  @override
  Future<GroupStatsOverview> fetchStats(String groupId) async {
    final detail = await _source.fetchGroupDetail(groupId);
    final transactions = await _source.fetchTransactions(groupId);
    final settlement = await _source.fetchSettlementOverview(groupId);
    return GroupStatsOverview(
      totalSpent: transactions
          .where((item) => item.splitStatus == GroupSplitStatus.posted)
          .fold(0, (sum, item) => sum + item.resolvedBaseTotalAmount),
      transactionCount: transactions
          .where((item) => item.splitStatus == GroupSplitStatus.posted)
          .length,
      pendingTransactionCount: transactions
          .where((item) => item.splitStatus != GroupSplitStatus.posted)
          .length,
      pendingSettlementCount: settlement.suggestions
          .where((item) => item.status != GroupSettlementStatus.completed)
          .length,
      memberCount: detail.activeMembers.length,
      currentUserBalance: detail.group.currentUserBalance,
    );
  }

  @override
  Future<List<GroupReactionSummary>> fetchReactionSummaries(
    String transactionId,
  ) => _source.fetchReactions(transactionId);

  @override
  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) => _source.toggleReaction(transactionId: transactionId, emoji: emoji);

  @override
  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) => _source.fetchMonthlyStats(groupId: groupId, month: month);

  @override
  Future<GroupBudget> fetchBudget(String groupId) async =>
      _budgets[groupId] ??= GroupBudget.defaults(groupId);

  @override
  Future<void> updateBudget(GroupBudget budget) async {
    _budgets[budget.groupId] = budget;
  }

  @override
  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) => _source.fetchSettlementHistory(groupId);

  @override
  Future<String> buildGroupReportCsv(String groupId) async {
    final detail = await fetchGroupDetail(groupId);
    final transactions = await fetchTransactions(groupId);
    final settlement = await fetchSettlementOverview(groupId);
    final rows = <List<String>>[
      ['Bao cao nhom', detail.group.name],
      [],
      ['Giao dich'],
      ['Ngay', 'Danh muc', 'Mo ta', 'So tien'],
      ...transactions.map(
        (item) => [
          item.transactionDate.toIso8601String(),
          item.categoryName ?? '',
          item.caption ?? item.note ?? '',
          item.totalAmount.toString(),
        ],
      ),
      [],
      ['Can doi'],
      ...settlement.balances.map(
        (item) => [
          item.displayName ?? item.userId,
          item.totalPaidAmount.toString(),
          item.totalShareAmount.toString(),
          item.balance.toString(),
        ],
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  @override
  Future<List<GroupFeedItem>> fetchFeed(String groupId) async {
    final transactions = await _source.fetchTransactions(groupId);
    return Future.wait(
      transactions.map((transaction) async {
        final detail = await _source.fetchTransactionDetail(transaction.id);
        return GroupFeedItem(
          transaction: transaction,
          reactions: await _source.fetchReactions(transaction.id),
          commentCount: detail.comments.length,
        );
      }),
    );
  }

  @override
  Future<List<GroupPhotoItem>> fetchPhotoAlbum(String groupId) async {
    final transactions = await _source.fetchTransactions(groupId);
    return transactions
        .where((item) => item.imagePath?.isNotEmpty == true)
        .map(
          (item) => GroupPhotoItem(
            transactionId: item.id,
            groupId: item.groupId,
            createdBy: item.createdBy,
            caption: item.caption ?? item.categoryName,
            imagePath: item.imagePath!,
            amount: item.totalAmount,
            transactionDate: item.transactionDate,
            creatorName: item.creatorName,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<GroupPublicProfile> fetchPublicProfile(String groupId) async =>
      _profiles[groupId] ??= GroupPublicProfile.defaults(groupId);

  @override
  Future<void> updatePublicProfile(GroupPublicProfile profile) async {
    _profiles[profile.groupId] = profile;
  }

  @override
  Future<void> markSettlementPaid(String settlementId) =>
      _source.markSettlementPaid(settlementId);

  @override
  Future<void> confirmSettlementReceived(String settlementId) =>
      _source.confirmSettlementReceived(settlementId);

  @override
  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  }) => _source.disputeSettlement(settlementId: settlementId, reason: reason);

  @override
  Future<void> resetDisputedSettlement(String settlementId) =>
      _source.resetDisputedSettlement(settlementId);

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) => _source.removeMember(groupId: groupId, userId: userId);

  @override
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) => _source.updateMemberRole(groupId: groupId, userId: userId, role: role);

  @override
  Future<void> leaveGroup(String groupId) => _source.leaveGroup(groupId);

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) => _source.transferOwnership(
    groupId: groupId,
    newOwnerUserId: newOwnerUserId,
  );

  @override
  Future<void> addComment({
    required String transactionId,
    required String content,
  }) => _source.addComment(transactionId: transactionId, content: content);

  @override
  Future<List<GroupReactionSummary>> fetchReactions(String transactionId) =>
      _source.fetchReactions(transactionId);

  @override
  Future<void> updateComment({
    required String commentId,
    required String transactionId,
    required String content,
  }) => _source.updateComment(
    commentId: commentId,
    transactionId: transactionId,
    content: content,
  );

  @override
  Future<void> deleteComment({
    required String commentId,
    required String transactionId,
  }) =>
      _source.deleteComment(commentId: commentId, transactionId: transactionId);

  @override
  Future<List<GroupActivity>> fetchActivities(String groupId) =>
      _source.fetchActivities(groupId);

  @override
  Future<List<GroupCommunityPost>> fetchCommunityPosts({
    required String groupId,
    int offset = 0,
    int limit = 30,
  }) => _source.fetchCommunityPosts(
    groupId: groupId,
    offset: offset,
    limit: limit,
  );

  @override
  Future<String> createCommunityPost({
    required String groupId,
    required String type,
    String? content,
    List<GroupCommunityMediaDraft> media = const [],
  }) => _source.createCommunityPost(
    groupId: groupId,
    type: type,
    content: content,
    media: media,
  );

  @override
  Future<void> updateCommunityPost({
    required String postId,
    required String content,
  }) => _source.updateCommunityPost(postId: postId, content: content);

  @override
  Future<void> deleteCommunityPost(String postId) =>
      _source.deleteCommunityPost(postId);

  @override
  Future<void> addCommunityPostComment({
    required String postId,
    required String content,
  }) => _source.addCommunityPostComment(postId: postId, content: content);

  @override
  Future<void> updateCommunityPostComment({
    required String commentId,
    required String content,
  }) => _source.updateCommunityPostComment(
    commentId: commentId,
    content: content,
  );

  @override
  Future<void> deleteCommunityPostComment(String commentId) =>
      _source.deleteCommunityPostComment(commentId);

  @override
  Future<void> toggleCommunityPostReaction({
    required String postId,
    required String emoji,
  }) => _source.toggleCommunityPostReaction(postId: postId, emoji: emoji);

  @override
  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId) =>
      _source.fetchAuditLogs(groupId);

  @override
  Future<List<GroupPoll>> fetchPolls(String groupId) =>
      _source.fetchPolls(groupId);

  @override
  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) => _source.createPoll(groupId: groupId, title: title, options: options);

  @override
  Future<void> votePoll({required String pollId, required String optionId}) =>
      _source.votePoll(pollId: pollId, optionId: optionId);

  @override
  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(String groupId) =>
      _source.fetchSavingsChallenges(groupId);

  @override
  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) => _source.createSavingsChallenge(
    groupId: groupId,
    title: title,
    targetAmount: targetAmount,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  }) => _source.addSavingsContribution(
    challengeId: challengeId,
    amount: amount,
    note: note,
  );

  @override
  Future<List<GroupNotification>> fetchNotifications({String? category}) =>
      _source.fetchNotifications(category: category);

  @override
  Future<void> markNotificationRead(String notificationId) =>
      _source.markNotificationRead(notificationId);

  @override
  Future<void> markAllNotificationsRead() => _source.markAllNotificationsRead();

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) async =>
      _preferences[groupId] ??= GroupNotificationPreference.defaults(groupId);

  @override
  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  ) async {
    _preferences[preference.groupId] = preference;
  }

  @override
  Future<GroupPublicProfile> fetchPublicGroupProfile(String slug) =>
      fetchPublicProfile(slug);

  @override
  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) async => List.unmodifiable(_recurring[groupId] ?? const []);

  @override
  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    bool autoPost = false,
  }) async {
    final now = DateTime.now();
    final item = GroupRecurringTransaction(
      id: 'mock-recurring-${_recurringSequence++}',
      groupId: groupId,
      createdBy: currentUserId,
      title: title,
      amount: amount,
      frequency: frequency,
      nextRunAt: nextRunAt,
      notifyDaysBefore: notifyDaysBefore,
      isActive: true,
      autoPost: autoPost,
      createdAt: now,
    );
    (_recurring[groupId] ??= []).add(item);
    return item.id;
  }

  @override
  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
    bool autoPost = false,
  }) async {
    for (final items in _recurring.values) {
      final index = items.indexWhere((item) => item.id == id);
      if (index == -1) continue;
      final old = items[index];
      items[index] = GroupRecurringTransaction(
        id: old.id,
        groupId: old.groupId,
        createdBy: old.createdBy,
        title: title,
        amount: amount,
        frequency: frequency,
        nextRunAt: nextRunAt,
        notifyDaysBefore: notifyDaysBefore,
        isActive: isActive,
        autoPost: autoPost,
        createdAt: old.createdAt,
      );
      return;
    }
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    for (final items in _recurring.values) {
      items.removeWhere((item) => item.id == id);
    }
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
