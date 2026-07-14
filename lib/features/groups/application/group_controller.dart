import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/group_repository_impl.dart';
import '../domain/entities/group_community.dart';
import '../domain/entities/group_roadmap.dart';
import '../domain/entities/group_settlement.dart';
import '../domain/entities/group_transaction.dart';
import '../domain/entities/group_invite.dart';
import '../domain/entities/spending_group.dart';

final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, List<SpendingGroup>>(
      GroupsController.new,
    );

final groupDetailProvider = FutureProvider.family<SpendingGroupDetail, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchGroupDetail(groupId);
});

final groupTransactionsProvider =
    FutureProvider.family<List<GroupTransaction>, String>((ref, groupId) {
      return ref.watch(groupRepositoryProvider).fetchTransactions(groupId);
    });

final groupTransactionDetailProvider =
    FutureProvider.family<GroupTransactionDetail, String>((ref, transactionId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchTransactionDetail(transactionId);
    });

final groupSettlementOverviewProvider =
    FutureProvider.family<GroupSettlementOverview, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchSettlementOverview(groupId);
    });

final groupReactionsProvider =
    FutureProvider.family<List<GroupReactionSummary>, String>((
      ref,
      transactionId,
    ) {
      return ref.watch(groupRepositoryProvider).fetchReactions(transactionId);
    });

final groupStatsProvider = FutureProvider.family<GroupStatsOverview, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchStats(groupId);
});

final groupActivitiesProvider =
    FutureProvider.family<List<GroupActivity>, String>((ref, groupId) {
      return ref.watch(groupRepositoryProvider).fetchActivities(groupId);
    });

final groupNotificationsProvider = FutureProvider<List<GroupNotification>>((
  ref,
) {
  return ref.watch(groupRepositoryProvider).fetchNotifications();
});

final groupNotificationPreferenceProvider =
    FutureProvider.family<GroupNotificationPreference, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchNotificationPreference(groupId);
    });

final groupTransactionReactionsProvider =
    FutureProvider.family<List<GroupReactionSummary>, String>((
      ref,
      transactionId,
    ) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchReactionSummaries(transactionId);
    });

typedef GroupMonthKey = ({String groupId, DateTime month});

final groupMonthlyStatsProvider =
    FutureProvider.family<GroupMonthlyStats, GroupMonthKey>((ref, key) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchMonthlyStats(groupId: key.groupId, month: key.month);
    });

final groupBudgetProvider = FutureProvider.family<GroupBudget, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchBudget(groupId);
});

final groupSettlementHistoryProvider =
    FutureProvider.family<List<GroupSettlementHistoryEntry>, String>((
      ref,
      groupId,
    ) {
      return ref.watch(groupRepositoryProvider).fetchSettlementHistory(groupId);
    });

final groupFeedProvider = FutureProvider.family<List<GroupFeedItem>, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchFeed(groupId);
});

final groupPhotoAlbumProvider =
    FutureProvider.family<List<GroupPhotoItem>, String>((ref, groupId) {
      return ref.watch(groupRepositoryProvider).fetchPhotoAlbum(groupId);
    });

final groupRecurringTransactionsProvider =
    FutureProvider.family<List<GroupRecurringTransaction>, String>((
      ref,
      groupId,
    ) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchRecurringTransactions(groupId);
    });

final groupPublicProfileProvider =
    FutureProvider.family<GroupPublicProfile, String>((ref, groupId) {
      return ref.watch(groupRepositoryProvider).fetchPublicProfile(groupId);
    });

final groupInvitePreviewProvider = FutureProvider.autoDispose
    .family<GroupInvitePreview, String>((ref, token) {
      return ref.watch(groupRepositoryProvider).fetchInvitePreview(token);
    });

final groupDirectInvitesProvider = FutureProvider<List<GroupDirectInvite>>((
  ref,
) {
  return ref.watch(groupRepositoryProvider).fetchDirectInvites();
});

final pendingGroupInviteCountProvider = Provider<int>((ref) {
  return ref
      .watch(groupDirectInvitesProvider)
      .when(
        data: (invites) => invites.where((invite) => invite.canRespond).length,
        loading: () => 0,
        error: (_, _) => 0,
      );
});

final currentGroupUserIdProvider = Provider<String>((ref) {
  return ref.watch(groupRepositoryProvider).currentUserId;
});

final groupActionControllerProvider =
    AsyncNotifierProvider<GroupActionController, void>(
      GroupActionController.new,
    );

class GroupsController extends AsyncNotifier<List<SpendingGroup>> {
  @override
  Future<List<SpendingGroup>> build() {
    return ref.read(groupRepositoryProvider).fetchGroups();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

class GroupActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
    String? avatarFilePath,
  }) {
    return _run(() async {
      final id = await ref
          .read(groupRepositoryProvider)
          .createGroup(
            name: name,
            description: description,
            type: type,
            avatarFilePath: avatarFilePath,
          );
      ref.invalidate(groupsControllerProvider);
      return id;
    });
  }

  Future<String> createInviteLink(String groupId) {
    return _run(
      () => ref.read(groupRepositoryProvider).createInviteLink(groupId),
    );
  }

  Future<GroupInviteAcceptResult> acceptInvite(String token) {
    return _run(() async {
      final result = await ref
          .read(groupRepositoryProvider)
          .acceptInvite(token);
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupNotificationsProvider);
      ref.invalidate(groupInvitePreviewProvider(token));
      _invalidateGroup(result.groupId);
      return result;
    });
  }

  Future<void> revokeInviteLink(String token) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).revokeInviteLink(token);
      ref.invalidate(groupInvitePreviewProvider(token));
    });
  }

  Future<void> declineInvite(String token) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).declineInvite(token);
      ref.invalidate(groupInvitePreviewProvider(token));
    });
  }

  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId) {
    return _run(() async {
      final result = await ref
          .read(groupRepositoryProvider)
          .acceptDirectInvite(inviteId);
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupDirectInvitesProvider);
      return result;
    });
  }

  Future<void> declineDirectInvite(String inviteId) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).declineDirectInvite(inviteId);
      ref.invalidate(groupDirectInvitesProvider);
    });
  }

  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .inviteByUsername(groupId: groupId, username: username);
      _invalidateGroup(groupId);
    });
  }

  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .inviteByUserId(groupId: groupId, userId: userId);
      _invalidateGroup(groupId);
    });
  }

  Future<String> createTransaction(GroupTransactionDraft draft) {
    return _run(() async {
      final id = await ref
          .read(groupRepositoryProvider)
          .createTransaction(draft);
      _invalidateGroup(draft.groupId);
      return id;
    });
  }

  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateTransaction(transactionId: transactionId, draft: draft);
      ref.invalidate(groupTransactionDetailProvider(transactionId));
      _invalidateGroup(draft.groupId);
    });
  }

  Future<void> deleteTransaction({
    required String transactionId,
    required String groupId,
  }) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).deleteTransaction(transactionId);
      ref.invalidate(groupTransactionDetailProvider(transactionId));
      _invalidateGroup(groupId);
    });
  }

  Future<void> submitMemberAmount({
    required String transactionId,
    required String groupId,
    required int shareAmount,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .submitMemberAmount(
            transactionId: transactionId,
            shareAmount: shareAmount,
          );
      ref.invalidate(groupTransactionDetailProvider(transactionId));
      _invalidateGroup(groupId);
    });
  }

  Future<void> markSettlementPaid({
    required String settlementId,
    required String groupId,
  }) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).markSettlementPaid(settlementId);
      ref.invalidate(groupSettlementOverviewProvider(groupId));
      ref.invalidate(groupStatsProvider(groupId));
      ref.invalidate(groupsControllerProvider);
    });
  }

  Future<void> confirmSettlementReceived({
    required String settlementId,
    required String groupId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .confirmSettlementReceived(settlementId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> disputeSettlement({
    required String settlementId,
    required String groupId,
  }) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).disputeSettlement(settlementId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> resetDisputedSettlement({
    required String settlementId,
    required String groupId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .resetDisputedSettlement(settlementId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> leaveGroup(String groupId) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).leaveGroup(groupId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .transferOwnership(groupId: groupId, newOwnerUserId: newOwnerUserId);
      _invalidateGroup(groupId);
      ref.invalidate(groupNotificationsProvider);
    });
  }

  Future<void> addComment({
    required String transactionId,
    required String content,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .addComment(transactionId: transactionId, content: content);
      ref.invalidate(groupTransactionDetailProvider(transactionId));
      ref.invalidate(groupActivitiesProvider);
    });
  }

  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .toggleReaction(transactionId: transactionId, emoji: emoji);
      ref.invalidate(groupReactionsProvider(transactionId));
      ref.invalidate(groupActivitiesProvider);
    });
  }

  Future<void> markNotificationRead(String notificationId) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .markNotificationRead(notificationId);
      ref.invalidate(groupNotificationsProvider);
    });
  }

  Future<void> updateComment({
    required String commentId,
    required String transactionId,
    required String content,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateComment(
            commentId: commentId,
            transactionId: transactionId,
            content: content,
          );
      ref.invalidate(groupTransactionDetailProvider(transactionId));
    });
  }

  Future<void> deleteComment({
    required String commentId,
    required String transactionId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .deleteComment(commentId: commentId, transactionId: transactionId);
      ref.invalidate(groupTransactionDetailProvider(transactionId));
    });
  }

  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateNotificationPreference(preference);
      ref.invalidate(groupNotificationPreferenceProvider(preference.groupId));
      ref.invalidate(groupNotificationsProvider);
    });
  }

  Future<void> updateBudget(GroupBudget budget) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).updateBudget(budget);
      ref.invalidate(groupBudgetProvider(budget.groupId));
      ref.invalidate(groupActivitiesProvider(budget.groupId));
    });
  }

  Future<String> buildGroupReportCsv(String groupId) {
    return _run(
      () => ref.read(groupRepositoryProvider).buildGroupReportCsv(groupId),
    );
  }

  Future<void> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .createRecurringTransaction(
            groupId: groupId,
            title: title,
            amount: amount,
            frequency: frequency,
            nextRunAt: nextRunAt,
            notifyDaysBefore: notifyDaysBefore,
          );
      ref.invalidate(groupRecurringTransactionsProvider(groupId));
      ref.invalidate(groupActivitiesProvider(groupId));
      ref.invalidate(groupNotificationsProvider);
    });
  }

  Future<void> updateRecurringTransactionActive({
    required String recurringTransactionId,
    required String groupId,
    required bool isActive,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateRecurringTransactionActive(
            recurringTransactionId: recurringTransactionId,
            isActive: isActive,
          );
      ref.invalidate(groupRecurringTransactionsProvider(groupId));
    });
  }

  Future<void> updatePublicProfile(GroupPublicProfile profile) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).updatePublicProfile(profile);
      ref.invalidate(groupPublicProfileProvider(profile.groupId));
      ref.invalidate(groupActivitiesProvider(profile.groupId));
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncLoading();
    try {
      final result = await action();
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      AppLogger.error('Group action failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _invalidateGroup(String groupId) {
    ref.invalidate(groupsControllerProvider);
    ref.invalidate(groupDetailProvider(groupId));
    ref.invalidate(groupTransactionsProvider(groupId));
    ref.invalidate(groupSettlementOverviewProvider(groupId));
    ref.invalidate(groupStatsProvider(groupId));
    ref.invalidate(groupActivitiesProvider(groupId));
    ref.invalidate(groupFeedProvider(groupId));
    ref.invalidate(groupPhotoAlbumProvider(groupId));
    ref.invalidate(groupBudgetProvider(groupId));
  }
}
