import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/group_repository_impl.dart';
import '../domain/entities/group_community.dart';
import '../domain/entities/group_roadmap.dart';
import '../domain/entities/group_settlement.dart';
import '../domain/entities/group_transaction.dart';
import '../domain/entities/group_invite.dart';
import '../domain/entities/spending_group.dart';
import '../domain/services/group_split_calculator.dart';

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

final groupBudgetProvider = FutureProvider.family<GroupBudget, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchBudget(groupId);
});

final groupNotificationPreferenceProvider =
    FutureProvider.family<GroupNotificationPreference, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchNotificationPreference(groupId);
    });

final groupPublicProfileProvider =
    FutureProvider.family<GroupPublicProfile, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchGroupPublicProfile(groupId);
    });

final publicGroupProfileProvider =
    FutureProvider.family<GroupPublicProfile, String>((ref, slug) {
      return ref.watch(groupRepositoryProvider).fetchPublicGroupProfile(slug);
    });

final groupTransactionDetailProvider =
    FutureProvider.family<GroupTransactionDetail, String>((ref, transactionId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchTransactionDetail(transactionId);
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

final groupSettlementOverviewProvider =
    FutureProvider.family<GroupSettlementOverview, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchSettlementOverview(groupId);
    });

final groupMonthlyStatsProvider =
    FutureProvider.family<
      GroupMonthlyStats,
      ({String groupId, DateTime month})
    >((ref, key) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchMonthlyStats(groupId: key.groupId, month: key.month);
    });

final groupSettlementHistoryProvider =
    FutureProvider.family<List<GroupSettlementHistoryEntry>, String>(
      (ref, groupId) =>
          ref.watch(groupRepositoryProvider).fetchSettlementHistory(groupId),
    );

final groupReactionsProvider =
    FutureProvider.family<List<GroupReactionSummary>, String>((
      ref,
      transactionId,
    ) {
      return ref.watch(groupRepositoryProvider).fetchReactions(transactionId);
    });

final groupActivitiesProvider =
    FutureProvider.family<List<GroupActivity>, String>((ref, groupId) {
      return ref.watch(groupRepositoryProvider).fetchActivities(groupId);
    });

final groupNotificationsProvider = FutureProvider<List<GroupNotification>>((
  ref,
) {
  return ref
      .watch(groupRepositoryProvider)
      .fetchNotifications(category: 'group');
});

final communityNotificationsProvider = FutureProvider<List<GroupNotification>>((
  ref,
) {
  return ref
      .watch(groupRepositoryProvider)
      .fetchNotifications(category: 'community');
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

final unreadGroupNotificationCountProvider = Provider<int>((ref) {
  final group = ref.watch(groupNotificationsProvider);
  final community = ref.watch(communityNotificationsProvider);
  int unread(AsyncValue<List<GroupNotification>> value) => value.when(
    data: (notifications) =>
        notifications.where((notification) => !notification.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
  return unread(group) + unread(community);
});

final unreadCommunityNotificationCountProvider = Provider<int>((ref) {
  return ref
      .watch(communityNotificationsProvider)
      .when(
        data: (notifications) =>
            notifications.where((notification) => !notification.isRead).length,
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

  Future<void> saveBudget(GroupBudget budget) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).saveBudget(budget);
      ref.invalidate(groupBudgetProvider(budget.groupId));
    });
  }

  Future<void> saveNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .saveNotificationPreference(preference);
      ref.invalidate(groupNotificationPreferenceProvider(preference.groupId));
    });
  }

  Future<void> saveGroupPublicProfile(GroupPublicProfile profile) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).saveGroupPublicProfile(profile);
      ref.invalidate(groupPublicProfileProvider(profile.groupId));
    });
  }

  Future<void> refreshRecurringTransactions(String groupId) async {
    ref.invalidate(groupRecurringTransactionsProvider(groupId));
  }

  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  }) {
    return _run(() async {
      final id = await ref
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
      return id;
    });
  }

  Future<void> updateRecurringTransaction({
    required String groupId,
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateRecurringTransaction(
            id: id,
            title: title,
            amount: amount,
            frequency: frequency,
            nextRunAt: nextRunAt,
            notifyDaysBefore: notifyDaysBefore,
            isActive: isActive,
          );
      ref.invalidate(groupRecurringTransactionsProvider(groupId));
    });
  }

  Future<void> deleteRecurringTransaction({
    required String groupId,
    required String id,
  }) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).deleteRecurringTransaction(id);
      ref.invalidate(groupRecurringTransactionsProvider(groupId));
    });
  }

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
      ref.invalidate(groupInvitePreviewProvider(token));
      return result;
    });
  }

  Future<void> revokeInviteLink(String token) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).revokeInviteLink(token);
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
      await _validateTransactionDraft(draft);
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
      await _validateTransactionDraft(draft);
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
    required String reason,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .disputeSettlement(settlementId: settlementId, reason: reason);
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
    });
  }

  Future<void> removeMember({required String groupId, required String userId}) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(groupId: groupId, userId: userId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> leaveGroup(String groupId) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).leaveGroup(groupId);
      _invalidateGroup(groupId);
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
      ref.invalidate(communityNotificationsProvider);
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
  }

  Future<void> _validateTransactionDraft(GroupTransactionDraft draft) async {
    final detail = await ref.read(groupDetailProvider(draft.groupId).future);
    const GroupSplitCalculator().validateDraft(
      totalAmount: draft.totalAmount,
      activeMemberIds: detail.activeMembers
          .map((member) => member.userId)
          .toList(growable: false),
      splitMode: draft.splitMode,
      paymentMode: draft.paymentMode,
      participantIds: draft.participantIds.isEmpty
          ? null
          : draft.participantIds,
      shareAmounts: draft.shareAmounts,
      payerAmounts: draft.payerAmounts,
    );
  }
}
