import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/group_repository_impl.dart';
import '../domain/entities/group_community.dart';
import '../domain/entities/group_community_feed.dart';
import '../domain/entities/group_enums.dart';
import '../domain/entities/group_roadmap.dart';
import '../domain/entities/group_settlement.dart';
import '../domain/entities/group_transaction.dart';
import '../domain/entities/group_invite.dart';
import '../domain/entities/spending_group.dart';
import '../domain/services/group_split_calculator.dart';

final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, GroupsState>(GroupsController.new);

class GroupsState {
  const GroupsState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<SpendingGroup> items;
  final bool hasMore;
  final bool isLoadingMore;

  GroupsState copyWith({
    List<SpendingGroup>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GroupsState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

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

final groupTransactionsPageProvider =
    FutureProvider.family<
      GroupTransactionPage,
      ({String groupId, int offset, int limit, String query, String? status})
    >((ref, key) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchTransactionsPage(
            groupId: key.groupId,
            offset: key.offset,
            limit: key.limit,
            query: key.query,
            status: key.status,
          );
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

final groupMonthlyTrendProvider =
    FutureProvider.family<List<GroupMonthlyStats>, String>((
      ref,
      groupId,
    ) async {
      final repository = ref.watch(groupRepositoryProvider);
      final now = DateTime.now();
      final months = List.generate(
        6,
        (index) => DateTime(now.year, now.month - (5 - index)),
      );
      return Future.wait(
        months.map(
          (month) =>
              repository.fetchMonthlyStats(groupId: groupId, month: month),
        ),
      );
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

final groupCommunityPostsProvider =
    FutureProvider.family<List<GroupCommunityPost>, String>((ref, groupId) {
      return ref
          .watch(groupRepositoryProvider)
          .fetchCommunityPosts(groupId: groupId);
    });

final groupCommunityFeedProvider =
    AsyncNotifierProvider.family<
      GroupCommunityFeedController,
      GroupCommunityFeed,
      String
    >(GroupCommunityFeedController.new);

final groupCommunityCommentsProvider =
    AsyncNotifierProvider.family<
      GroupCommunityCommentsController,
      GroupCommunityCommentsPage,
      String
    >(GroupCommunityCommentsController.new);

final groupAuditLogsProvider =
    FutureProvider.family<List<GroupAuditLog>, String>(
      (ref, groupId) =>
          ref.watch(groupRepositoryProvider).fetchAuditLogs(groupId),
    );

final groupPollsProvider = FutureProvider.family<List<GroupPoll>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).fetchPolls(groupId),
);
final groupSavingsChallengesProvider =
    FutureProvider.family<List<GroupSavingsChallenge>, String>(
      (ref, groupId) =>
          ref.watch(groupRepositoryProvider).fetchSavingsChallenges(groupId),
    );

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

final groupBudgetProvider = FutureProvider.family<GroupBudget, String>((
  ref,
  groupId,
) {
  return ref.watch(groupRepositoryProvider).fetchBudget(groupId);
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

class GroupMediaUploadProgress {
  const GroupMediaUploadProgress({
    required this.groupId,
    required this.completed,
    required this.total,
  });

  final String groupId;
  final int completed;
  final int total;

  double get fraction => total == 0 ? 0 : completed / total;
}

final groupMediaUploadProgressProvider =
    NotifierProvider<
      GroupMediaUploadProgressController,
      GroupMediaUploadProgress?
    >(GroupMediaUploadProgressController.new);

class GroupMediaUploadProgressController
    extends Notifier<GroupMediaUploadProgress?> {
  @override
  GroupMediaUploadProgress? build() => null;

  void update(GroupMediaUploadProgress progress) => state = progress;

  void clear() => state = null;
}

class GroupsController extends AsyncNotifier<GroupsState> {
  @override
  Future<GroupsState> build() async {
    final page = await ref
        .watch(groupRepositoryProvider)
        .fetchGroupsPage(limit: 20);
    return GroupsState(items: page.items, hasMore: page.hasMore);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final last = current.items.last;
      final page = await ref
          .read(groupRepositoryProvider)
          .fetchGroupsPage(
            limit: 20,
            beforeUpdatedAt: last.updatedAt,
            beforeId: last.id,
          );
      state = AsyncData(
        GroupsState(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load more groups', error, stackTrace);
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }
}

class GroupCommunityFeedController extends AsyncNotifier<GroupCommunityFeed> {
  GroupCommunityFeedController(this.groupId);

  final String groupId;

  @override
  Future<GroupCommunityFeed> build() async {
    final page = await ref
        .watch(groupRepositoryProvider)
        .fetchCommunityFeedPage(groupId: groupId, limit: 20);
    return GroupCommunityFeed(
      items: page.items,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await ref
          .read(groupRepositoryProvider)
          .fetchCommunityFeedPage(
            groupId: groupId,
            limit: 20,
            before: current.nextCursor,
          );
      state = AsyncData(
        GroupCommunityFeed(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load more community feed', error, stackTrace);
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  void updatePost(
    String postId,
    GroupCommunityPost Function(GroupCommunityPost post) update,
  ) {
    _replaceItem(postId, (item) {
      final post = item.post;
      return post == null ? item : _copyItem(item, post: update(post));
    });
  }

  void togglePostReaction(String postId, String emoji) {
    updatePost(postId, (post) {
      final existing = post.reactions
          .where((reaction) => reaction.emoji == emoji)
          .firstOrNull;
      final selected = existing?.reactedByCurrentUser ?? false;
      final nextCount = selected
          ? ((existing?.count ?? 1) - 1).clamp(0, existing?.count ?? 1)
          : (existing?.count ?? 0) + 1;
      final updated = <GroupCommunityReactionSummary>[
        for (final reaction in post.reactions)
          if (reaction.emoji != emoji) reaction,
        if (nextCount > 0)
          GroupCommunityReactionSummary(
            emoji: emoji,
            count: nextCount,
            reactedByCurrentUser: !selected,
          ),
      ];
      return post.copyWith(reactions: updated);
    });
  }

  void removePost(String postId) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .where((item) => item.sourceId != postId)
            .toList(growable: false),
      ),
    );
  }

  void applyPollVote(String pollId, String optionId) {
    _replaceItem(pollId, (item) {
      final poll = item.poll;
      if (poll == null || poll.selectedOptionId == optionId) return item;
      final options = poll.options
          .map(
            (option) => GroupPollOption(
              id: option.id,
              label: option.label,
              voteCount: option.id == optionId
                  ? option.voteCount + 1
                  : option.id == poll.selectedOptionId
                  ? (option.voteCount - 1).clamp(0, option.voteCount)
                  : option.voteCount,
            ),
          )
          .toList(growable: false);
      return _copyItem(
        item,
        poll: poll.copyWith(options: options, selectedOptionId: optionId),
      );
    });
  }

  void addChallengeContribution(String challengeId, int amount) {
    _replaceItem(challengeId, (item) {
      final challenge = item.challenge;
      if (challenge == null) return item;
      final total = (challenge.totalContributed + amount).clamp(
        0,
        challenge.targetAmount,
      );
      return _copyItem(
        item,
        challenge: challenge.copyWith(
          totalContributed: total,
          isActive: total < challenge.targetAmount,
        ),
      );
    });
  }

  void _replaceItem(
    String sourceId,
    GroupCommunityFeedItem Function(GroupCommunityFeedItem item) update,
  ) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((item) => item.sourceId == sourceId ? update(item) : item)
            .toList(growable: false),
      ),
    );
  }

  GroupCommunityFeedItem _copyItem(
    GroupCommunityFeedItem item, {
    GroupCommunityPost? post,
    GroupPoll? poll,
    GroupSavingsChallenge? challenge,
  }) {
    return GroupCommunityFeedItem(
      id: item.id,
      sourceId: item.sourceId,
      groupId: item.groupId,
      type: item.type,
      createdAt: item.createdAt,
      post: post ?? item.post,
      poll: poll ?? item.poll,
      activity: item.activity,
      challenge: challenge ?? item.challenge,
      transaction: item.transaction,
    );
  }
}

class GroupCommunityCommentsController
    extends AsyncNotifier<GroupCommunityCommentsPage> {
  GroupCommunityCommentsController(this.postId);

  final String postId;

  @override
  Future<GroupCommunityCommentsPage> build() {
    return ref
        .watch(groupRepositoryProvider)
        .fetchCommunityCommentsPage(postId: postId, limit: 30);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.items.isEmpty) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final last = current.items.last;
      final page = await ref
          .read(groupRepositoryProvider)
          .fetchCommunityCommentsPage(
            postId: postId,
            limit: 30,
            beforeCreatedAt: last.createdAt,
            beforeId: last.id,
          );
      state = AsyncData(
        GroupCommunityCommentsPage(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load more community comments',
        error,
        stackTrace,
      );
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }
}

class GroupActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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
    bool autoPost = false,
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
            autoPost: autoPost,
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
    bool autoPost = false,
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
            autoPost: autoPost,
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

  Future<void> votePoll({
    required String groupId,
    required String pollId,
    required String optionId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .votePoll(pollId: pollId, optionId: optionId);
      ref
          .read(groupCommunityFeedProvider(groupId).notifier)
          .applyPollVote(pollId, optionId);
      ref.invalidate(groupPollsProvider(groupId));
      ref.invalidate(groupActivitiesProvider(groupId));
    });
  }

  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) {
    return _run(() async {
      final id = await ref
          .read(groupRepositoryProvider)
          .createPoll(groupId: groupId, title: title, options: options);
      ref.invalidate(groupPollsProvider(groupId));
      await ref.read(groupCommunityFeedProvider(groupId).notifier).refresh();
      ref.invalidate(groupActivitiesProvider(groupId));
      return id;
    });
  }

  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _run(() async {
      final id = await ref
          .read(groupRepositoryProvider)
          .createSavingsChallenge(
            groupId: groupId,
            title: title,
            targetAmount: targetAmount,
            startDate: startDate,
            endDate: endDate,
          );
      ref.invalidate(groupSavingsChallengesProvider(groupId));
      await ref.read(groupCommunityFeedProvider(groupId).notifier).refresh();
      ref.invalidate(groupActivitiesProvider(groupId));
      return id;
    });
  }

  Future<void> addSavingsContribution({
    required String groupId,
    required String challengeId,
    required int amount,
    String? note,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .addSavingsContribution(
            challengeId: challengeId,
            amount: amount,
            note: note,
          );
      ref
          .read(groupCommunityFeedProvider(groupId).notifier)
          .addChallengeContribution(challengeId, amount);
      ref.invalidate(groupSavingsChallengesProvider(groupId));
      ref.invalidate(groupActivitiesProvider(groupId));
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

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateGroup(
            groupId: groupId,
            name: name,
            description: description,
            type: type,
          );
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupDetailProvider(groupId));
    });
  }

  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateGroupAvatar(groupId: groupId, filePath: filePath);
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupDetailProvider(groupId));
    });
  }

  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateGroupCurrency(groupId: groupId, baseCurrency: baseCurrency);
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupDetailProvider(groupId));
    });
  }

  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .setGroupArchived(groupId: groupId, archived: archived);
      ref.invalidate(groupsControllerProvider);
      ref.invalidate(groupDetailProvider(groupId));
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
    required String reason,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .disputeSettlement(settlementId: settlementId, reason: reason);
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

  Future<void> removeMember({required String groupId, required String userId}) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(groupId: groupId, userId: userId);
      _invalidateGroup(groupId);
    });
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateMemberRole(groupId: groupId, userId: userId, role: role);
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

  Future<String> createCommunityPost({
    required String groupId,
    required String type,
    String? content,
    List<GroupCommunityMediaDraft> media = const [],
  }) {
    return _run(() async {
      try {
        final id = await ref
            .read(groupRepositoryProvider)
            .createCommunityPost(
              groupId: groupId,
              type: type,
              content: content,
              media: media,
              onMediaUploadProgress: (completed, total) {
                ref
                    .read(groupMediaUploadProgressProvider.notifier)
                    .update(
                      GroupMediaUploadProgress(
                        groupId: groupId,
                        completed: completed,
                        total: total,
                      ),
                    );
              },
            );
        ref.invalidate(groupCommunityPostsProvider(groupId));
        await ref.read(groupCommunityFeedProvider(groupId).notifier).refresh();
        ref.invalidate(groupActivitiesProvider(groupId));
        return id;
      } finally {
        ref.read(groupMediaUploadProgressProvider.notifier).clear();
      }
    });
  }

  Future<void> addCommunityPostComment({
    required String groupId,
    required String postId,
    required String content,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .addCommunityPostComment(postId: postId, content: content);
      ref.invalidate(groupCommunityPostsProvider(groupId));
      ref.invalidate(groupCommunityCommentsProvider(postId));
      ref
          .read(groupCommunityFeedProvider(groupId).notifier)
          .updatePost(
            postId,
            (post) => post.copyWith(commentCount: post.commentCount + 1),
          );
      ref.invalidate(groupActivitiesProvider(groupId));
    });
  }

  Future<void> updateCommunityPost({
    required String groupId,
    required String postId,
    required String content,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateCommunityPost(postId: postId, content: content);
      ref.invalidate(groupCommunityPostsProvider(groupId));
      ref
          .read(groupCommunityFeedProvider(groupId).notifier)
          .updatePost(postId, (post) => post.copyWith(content: content));
    });
  }

  Future<void> updateCommunityPostComment({
    required String groupId,
    required String postId,
    required String commentId,
    required String content,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .updateCommunityPostComment(commentId: commentId, content: content);
      ref.invalidate(groupCommunityPostsProvider(groupId));
      ref.invalidate(groupCommunityCommentsProvider(postId));
    });
  }

  Future<void> deleteCommunityPostComment({
    required String groupId,
    required String postId,
    required String commentId,
  }) {
    return _run(() async {
      await ref
          .read(groupRepositoryProvider)
          .deleteCommunityPostComment(commentId);
      ref.invalidate(groupCommunityPostsProvider(groupId));
      ref.invalidate(groupCommunityCommentsProvider(postId));
      ref
          .read(groupCommunityFeedProvider(groupId).notifier)
          .updatePost(
            postId,
            (post) => post.copyWith(
              commentCount: (post.commentCount - 1).clamp(0, post.commentCount),
            ),
          );
    });
  }

  Future<void> deleteCommunityPost({
    required String groupId,
    required String postId,
  }) {
    return _run(() async {
      await ref.read(groupRepositoryProvider).deleteCommunityPost(postId);
      ref.invalidate(groupCommunityPostsProvider(groupId));
      ref.read(groupCommunityFeedProvider(groupId).notifier).removePost(postId);
    });
  }

  Future<void> toggleCommunityPostReaction({
    required String groupId,
    required String postId,
    required String emoji,
  }) {
    final feed = ref.read(groupCommunityFeedProvider(groupId).notifier);
    feed.togglePostReaction(postId, emoji);
    return _run(() async {
      try {
        await ref
            .read(groupRepositoryProvider)
            .toggleCommunityPostReaction(postId: postId, emoji: emoji);
        ref.invalidate(groupCommunityPostsProvider(groupId));
        ref.invalidate(groupActivitiesProvider(groupId));
      } catch (_) {
        feed.togglePostReaction(postId, emoji);
        rethrow;
      }
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

  Future<void> markAllNotificationsRead() {
    return _run(() async {
      await ref.read(groupRepositoryProvider).markAllNotificationsRead();
      ref.invalidate(groupNotificationsProvider);
      ref.invalidate(communityNotificationsProvider);
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
