import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_community_feed.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import 'group_route_paths.dart';

class GroupCommunityScreen extends ConsumerStatefulWidget {
  const GroupCommunityScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupCommunityScreen> createState() =>
      _GroupCommunityScreenState();
}

enum _CommunityFilter { all, polls, activity }

class _GroupCommunityScreenState extends ConsumerState<GroupCommunityScreen> {
  _CommunityFilter _filter = _CommunityFilter.all;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(groupCommunityFeedProvider(widget.groupId));
    final detail = ref.watch(groupDetailProvider(widget.groupId)).asData?.value;
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: SafeArea(
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: userFriendlyMessage(context, error),
            onRetry: () =>
                ref.invalidate(groupCommunityFeedProvider(widget.groupId)),
          ),
          data: (feed) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupCommunityFeedProvider(widget.groupId));
              await ref.read(groupCommunityFeedProvider(widget.groupId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                _CommunityTopBar(groupId: widget.groupId),
                const SizedBox(height: 10),
                if (detail != null) _CommunityGroupHeader(detail: detail),
                if (detail != null) const SizedBox(height: 12),
                _ComposerLauncher(onTap: () => _openComposer(context)),
                const SizedBox(height: 14),
                _FilterBar(
                  filter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 14),
                ..._filteredItems(feed.items).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeedItemCard(
                      key: ValueKey(item.id),
                      item: item,
                      groupId: widget.groupId,
                      onCommentPost: (post) => _showComments(context, post),
                      onVote: (poll, optionId) => _votePoll(poll, optionId),
                      onContribute: (challenge) =>
                          _contributeToChallenge(context, challenge),
                    ),
                  ),
                ),
                if (_filteredItems(feed.items).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Text(
                      context.l10n.groupCommunityNoFeed,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textDim),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<GroupCommunityFeedItem> _filteredItems(
    List<GroupCommunityFeedItem> items,
  ) {
    return items
        .where((item) {
          switch (_filter) {
            case _CommunityFilter.all:
              return true;
            case _CommunityFilter.polls:
              return item.type == GroupCommunityFeedItemType.poll;
            case _CommunityFilter.activity:
              return item.type == GroupCommunityFeedItemType.activity ||
                  item.type == GroupCommunityFeedItemType.transaction;
          }
        })
        .toList(growable: false);
  }

  Future<void> _openComposer(BuildContext context) async {
    final action = await showModalBottomSheet<_CommunityCreationAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _CommunityCreateActivitySheet(
        canCreateChallenge:
            ref
                .read(groupDetailProvider(widget.groupId))
                .asData
                ?.value
                .canInvite ??
            false,
      ),
    );
    if (action == null || !context.mounted) return;

    // The previous implementation opened a Dialog immediately after popping
    // the BottomSheet. Waiting for the overlay tree to finish deactivation
    // prevents Flutter's InheritedElement `_dependents.isEmpty` assertion.
    await _waitForOverlayToSettle();
    if (!context.mounted) return;

    if (action == _CommunityCreationAction.poll) {
      await _createPoll(context);
      return;
    }
    if (action == _CommunityCreationAction.challenge) {
      await _createChallenge(context);
      return;
    }
    await _openPostComposer(context);
  }

  Future<void> _openPostComposer(BuildContext context) async {
    final result = await showModalBottomSheet<_CommunityComposerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CommunityComposerSheet(),
    );
    if (result == null || !context.mounted) return;
    if ((result.content?.trim().isEmpty ?? true) && result.media.isEmpty) {
      _showMessage(context, context.l10n.groupCommunityPostEmpty);
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createCommunityPost(
            groupId: widget.groupId,
            type: result.media.isEmpty ? 'text' : 'photo',
            content: result.content,
            media: result.media,
          );
      if (!context.mounted) return;
      _showMessage(context, context.l10n.groupCommunityPostCreated);
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, userFriendlyMessage(context, error));
      }
    }
  }

  Future<void> _createPoll(BuildContext context) async {
    final result = await showDialog<(String, List<String>)>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _PollDialog(),
    );
    await _waitForOverlayToSettle();
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createPoll(
            groupId: widget.groupId,
            title: result.$1,
            options: result.$2,
          );
      if (context.mounted) {
        _showMessage(context, context.l10n.groupCommunityPollCreated);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, userFriendlyMessage(context, error));
      }
    }
  }

  Future<void> _createChallenge(BuildContext context) async {
    final result = await showDialog<(String, int)>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _ChallengeDialog(),
    );
    await _waitForOverlayToSettle();
    if (result == null || !context.mounted) return;
    final now = DateTime.now();
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createSavingsChallenge(
            groupId: widget.groupId,
            title: result.$1,
            targetAmount: result.$2,
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
          );
      if (context.mounted) {
        _showMessage(context, context.l10n.groupCommunityChallengeCreated);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, userFriendlyMessage(context, error));
      }
    }
  }

  Future<void> _votePoll(GroupPoll poll, String optionId) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .votePoll(
            groupId: widget.groupId,
            pollId: poll.id,
            optionId: optionId,
          );
      if (mounted) {
        _showMessage(context, context.l10n.groupCommunityPollVoteRecorded);
      }
    } catch (error) {
      if (mounted) _showMessage(context, userFriendlyMessage(context, error));
    }
  }

  Future<void> _waitForOverlayToSettle() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _contributeToChallenge(
    BuildContext context,
    GroupSavingsChallenge challenge,
  ) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _ContributionDialog(
        challenge: challenge,
        remainingText: ref.formatAmount(
          (challenge.targetAmount - challenge.totalContributed).clamp(
            0,
            challenge.targetAmount,
          ),
        ),
        controller: controller,
        onCancel: () => Navigator.pop(dialogContext),
        onSubmit: () => Navigator.pop(
          dialogContext,
          int.tryParse(controller.text.replaceAll(',', '')),
        ),
      ),
    );
    controller.dispose();
    if (amount == null || amount <= 0 || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .addSavingsContribution(
            groupId: widget.groupId,
            challengeId: challenge.id,
            amount: amount,
          );
      if (context.mounted) {
        _showMessage(context, context.l10n.groupCommunityContributionRecorded);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, userFriendlyMessage(context, error));
      }
    }
  }

  Future<void> _showComments(
    BuildContext context,
    GroupCommunityPost post,
  ) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.groupCommunityComment,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (post.comments.isEmpty)
                Text(
                  context.l10n.groupCommunityCommentEmpty,
                  style: TextStyle(color: context.moniaryColors.textDim),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: post.comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final comment = post.comments[index];
                      return Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${comment.displayName ?? comment.userId}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: comment.content),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: context.l10n.groupCommunityCommentHint,
                  suffixIcon: IconButton(
                    tooltip: context.l10n.groupCommunityComment,
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () async {
                      final value = controller.text.trim();
                      if (value.isEmpty) return;
                      try {
                        await ref
                            .read(groupActionControllerProvider.notifier)
                            .addCommunityPostComment(
                              groupId: widget.groupId,
                              postId: post.id,
                              content: value,
                            );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } catch (error) {
                        if (sheetContext.mounted) {
                          _showMessage(
                            sheetContext,
                            userFriendlyMessage(sheetContext, error),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CommunityTopBar extends StatelessWidget {
  const _CommunityTopBar({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(GroupRoutePaths.home(groupId));
          }
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      Expanded(
        child: Text(
          context.l10n.groupCommunityTab,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        tooltip: context.l10n.groupCommunityOpenNotifications,
        onPressed: () => context.go(GroupRoutePaths.notifications(groupId)),
        icon: const Icon(Icons.notifications_none_rounded),
      ),
      IconButton(
        tooltip: context.l10n.groupCommunityOpenManagement,
        onPressed: () => _openMore(context),
        icon: const Icon(Icons.more_vert_rounded),
      ),
    ],
  );

  Future<void> _openMore(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.groupCommunityAlbumAction),
              onTap: () => Navigator.pop(sheetContext, 'album'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(context.l10n.groupCommunityOpenManagement),
              onTap: () => Navigator.pop(sheetContext, 'management'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'album') {
      await context.push(GroupRoutePaths.album(groupId));
    } else if (action == 'management') {
      context.go(GroupRoutePaths.management(groupId));
    }
  }
}

class _CommunityGroupHeader extends StatelessWidget {
  const _CommunityGroupHeader({required this.detail});

  final SpendingGroupDetail detail;

  @override
  Widget build(BuildContext context) {
    final members = detail.activeMembers;
    return Row(
      children: [
        ClipOval(
          child: SupabaseImage(
            imagePath: detail.group.avatarPath,
            width: 66,
            height: 66,
            fallbackBuilder: (_) =>
                _GroupAvatarFallback(label: detail.group.name, size: 66),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${members.length} ${context.l10n.groupMemberFallback.toLowerCase()}',
                style: TextStyle(color: context.moniaryColors.textDim),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 26,
                child: Stack(
                  children: [
                    for (var index = 0; index < members.take(5).length; index++)
                      Positioned(
                        left: index * 21,
                        child: ClipOval(
                          child: SupabaseImage(
                            imagePath: members[index].avatarPath,
                            width: 26,
                            height: 26,
                            fallbackBuilder: (_) => _MemberAvatarFallback(
                              label: members[index].resolvedName,
                            ),
                          ),
                        ),
                      ),
                    if (members.length > 5)
                      Positioned(
                        left: 5 * 21,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: context.moniaryColors.backgroundSoft,
                          child: Text('+${members.length - 5}'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComposerLauncher extends StatelessWidget {
  const _ComposerLauncher({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: context.moniaryColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.moniaryColors.outline),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 17,
            child: Icon(Icons.person_outline, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.groupCommunityComposerHint,
              style: TextStyle(color: context.moniaryColors.textDim),
            ),
          ),
          Icon(Icons.add_circle_outline, color: context.moniaryColors.primary),
        ],
      ),
    ),
  );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final _CommunityFilter filter;
  final ValueChanged<_CommunityFilter> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _FilterPill(
          label: context.l10n.groupCommunityAllTab,
          selected: filter == _CommunityFilter.all,
          onTap: () => onChanged(_CommunityFilter.all),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _FilterPill(
          label: context.l10n.groupCommunityPollTab,
          selected: filter == _CommunityFilter.polls,
          onTap: () => onChanged(_CommunityFilter.polls),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _FilterPill(
          label: context.l10n.groupCommunityActivityTab,
          selected: filter == _CommunityFilter.activity,
          onTap: () => onChanged(_CommunityFilter.activity),
        ),
      ),
    ],
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(42),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      backgroundColor: selected
          ? context.moniaryColors.primary
          : context.moniaryColors.surface,
      foregroundColor: selected
          ? Colors.white
          : context.moniaryColors.textSecondary,
      side: BorderSide(
        color: selected
            ? context.moniaryColors.primary
            : context.moniaryColors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _FeedItemCard extends ConsumerWidget {
  const _FeedItemCard({
    required this.item,
    required this.groupId,
    required this.onCommentPost,
    required this.onVote,
    required this.onContribute,
    super.key,
  });

  final GroupCommunityFeedItem item;
  final String groupId;
  final ValueChanged<GroupCommunityPost> onCommentPost;
  final Future<void> Function(GroupPoll poll, String optionId) onVote;
  final Future<void> Function(GroupSavingsChallenge challenge) onContribute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (item.type) {
      case GroupCommunityFeedItemType.post:
        return _PostCard(
          post: item.post!,
          groupId: groupId,
          onComment: onCommentPost,
        );
      case GroupCommunityFeedItemType.poll:
        return _PollFeedCard(poll: item.poll!, onVote: onVote);
      case GroupCommunityFeedItemType.challenge:
        return _ChallengeFeedCard(
          challenge: item.challenge!,
          onContribute: onContribute,
        );
      case GroupCommunityFeedItemType.activity:
        return _ActivityFeedCard(activity: item.activity!);
      case GroupCommunityFeedItemType.transaction:
        return _TransactionFeedCard(
          transaction: item.transaction!,
          groupId: groupId,
        );
    }
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({
    required this.post,
    required this.groupId,
    required this.onComment,
  });

  final GroupCommunityPost post;
  final String groupId;
  final ValueChanged<GroupCommunityPost> onComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MoniaryEditorialCard(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostAuthorRow(post: post),
        if (post.content?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 11),
          Text(post.content!),
        ],
        if (post.media.isNotEmpty) ...[
          const SizedBox(height: 11),
          _PostMediaGrid(media: post.media),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            for (final emoji in const ['❤️', '👍', '🎉'])
              _ReactionButton(
                emoji: emoji,
                count: _reactionCount(post.reactions, emoji),
                selected: _reactionSelected(post.reactions, emoji),
                onTap: () => ref
                    .read(groupActionControllerProvider.notifier)
                    .toggleCommunityPostReaction(
                      groupId: groupId,
                      postId: post.id,
                      emoji: emoji,
                    ),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => onComment(post),
              icon: const Icon(Icons.mode_comment_outlined, size: 16),
              label: Text('${post.comments.length}'),
            ),
          ],
        ),
      ],
    ),
  );

  int _reactionCount(List<GroupCommunityReactionSummary> items, String emoji) =>
      items
          .where((item) => item.emoji == emoji)
          .fold(0, (sum, item) => sum + item.count);

  bool _reactionSelected(
    List<GroupCommunityReactionSummary> items,
    String emoji,
  ) => items.any((item) => item.emoji == emoji && item.reactedByCurrentUser);
}

class _PollFeedCard extends StatefulWidget {
  const _PollFeedCard({required this.poll, required this.onVote});

  final GroupPoll poll;
  final Future<void> Function(GroupPoll poll, String optionId) onVote;

  @override
  State<_PollFeedCard> createState() => _PollFeedCardState();
}

class _PollFeedCardState extends State<_PollFeedCard> {
  String? _selectedOptionId;
  bool _isVoting = false;

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final totalVotes = poll.options.fold<int>(
      0,
      (sum, option) => sum + option.voteCount,
    );
    final selectedOption = poll.options
        .where((option) => option.id == _selectedOptionId)
        .firstOrNull;
    final hasVoted = selectedOption != null && !_isVoting;

    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.moniaryColors.primary.withValues(
                  alpha: 0.12,
                ),
                child: Icon(
                  Icons.poll_outlined,
                  color: context.moniaryColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.groupCommunityPollTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$totalVotes ${context.l10n.groupCommunityVoters}',
                style: context.moniaryTypography.metadata,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(poll.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            poll.isClosed
                ? context.l10n.groupCommunityPollClosed
                : context.l10n.groupCommunityPollInstruction,
            style: TextStyle(color: context.moniaryColors.textDim),
          ),
          const SizedBox(height: 12),
          for (final option in poll.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: poll.isClosed || _isVoting
                    ? null
                    : () => setState(() => _selectedOptionId = option.id),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  decoration: BoxDecoration(
                    color: _selectedOptionId == option.id
                        ? context.moniaryColors.primary.withValues(alpha: 0.1)
                        : context.moniaryColors.backgroundSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedOptionId == option.id
                          ? context.moniaryColors.primary
                          : context.moniaryColors.outline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedOptionId == option.id
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: _selectedOptionId == option.id
                                ? context.moniaryColors.primary
                                : context.moniaryColors.textDim,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option.label)),
                          Text(
                            '${totalVotes == 0 ? 0 : (option.voteCount * 100 ~/ totalVotes)}%',
                            style: TextStyle(
                              color: context.moniaryColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: totalVotes == 0
                            ? 0
                            : option.voteCount / totalVotes,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(6),
                        color: context.moniaryColors.primary,
                        backgroundColor: context.moniaryColors.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          if (selectedOption != null && hasVoted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.groupCommunityPollSelected(selectedOption.label),
                style: TextStyle(
                  color: context.moniaryColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: poll.isClosed || _selectedOptionId == null || _isVoting
                  ? null
                  : _submitVote,
              icon: _isVoting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      hasVoted
                          ? Icons.check_circle_outline_rounded
                          : Icons.how_to_vote_outlined,
                    ),
              label: Text(
                poll.isClosed
                    ? context.l10n.groupCommunityPollClosed
                    : hasVoted
                    ? context.l10n.groupCommunityPollVoteRecorded
                    : context.l10n.groupCommunityPollVoteAction,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVote() async {
    final optionId = _selectedOptionId;
    if (optionId == null || _isVoting) return;
    setState(() => _isVoting = true);
    try {
      await widget.onVote(widget.poll, optionId);
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }
}

class _ChallengeFeedCard extends ConsumerStatefulWidget {
  const _ChallengeFeedCard({
    required this.challenge,
    required this.onContribute,
  });

  final GroupSavingsChallenge challenge;
  final Future<void> Function(GroupSavingsChallenge challenge) onContribute;

  @override
  ConsumerState<_ChallengeFeedCard> createState() => _ChallengeFeedCardState();
}

class _ChallengeFeedCardState extends ConsumerState<_ChallengeFeedCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final progress = challenge.targetAmount <= 0
        ? 0.0
        : (challenge.totalContributed / challenge.targetAmount)
              .clamp(0.0, 1.0)
              .toDouble();
    final remaining = (challenge.targetAmount - challenge.totalContributed)
        .clamp(0, challenge.targetAmount);
    final completed = progress >= 1;
    final date = MaterialLocalizations.of(
      context,
    ).formatShortDate(challenge.endDate);

    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.moniaryColors.success.withValues(
                  alpha: 0.18,
                ),
                child: Icon(
                  Icons.savings_outlined,
                  color: context.moniaryColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.groupCommunityChallengeTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: context.moniaryColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(challenge.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            completed
                ? context.l10n.groupCommunityChallengeCompleted
                : context.l10n.groupCommunityChallengeInstruction,
            style: TextStyle(color: context.moniaryColors.textDim),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: context.moniaryColors.success,
            backgroundColor: context.moniaryColors.outline,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${context.l10n.groupCommunityChallengeSaved}: ${ref.formatAmount(challenge.totalContributed)} / ${ref.formatAmount(challenge.targetAmount)}',
                  style: context.moniaryTypography.metadataStrong,
                ),
              ),
              Text(
                '${context.l10n.groupCommunityChallengeEnds}: $date',
                style: context.moniaryTypography.metadata,
              ),
            ],
          ),
          if (!completed && remaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${context.l10n.groupCommunityChallengeRemaining}: ${ref.formatAmount(remaining)}',
              style: TextStyle(color: context.moniaryColors.success),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !challenge.isActive || completed || _isSubmitting
                  ? null
                  : _openContribution,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                completed
                    ? context.l10n.groupCommunityChallengeCompleted
                    : challenge.isActive
                    ? context.l10n.groupCommunityContribute
                    : context.l10n.groupCommunityChallengeClosed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openContribution() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onContribute(widget.challenge);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ActivityFeedCard extends StatelessWidget {
  const _ActivityFeedCard({required this.activity});

  final GroupActivity activity;

  @override
  Widget build(BuildContext context) {
    final label = switch (activity.type) {
      'settlement_completed' => context.l10n.groupCommunityActivitySettlement,
      'member_left' => context.l10n.groupCommunityActivityMemberLeft,
      'community_post_created' ||
      'poll_created' => context.l10n.groupCommunityActivityPost,
      'transaction_created' => context.l10n.groupCommunityActivityTransaction,
      _ => context.l10n.groupCommunityActivityGeneric,
    };
    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: context.moniaryColors.success.withValues(
              alpha: 0.18,
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.moniaryColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${activity.actorName ?? context.l10n.groupMemberFallback} ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: label),
                ],
              ),
            ),
          ),
          if (activity.type == 'settlement_completed')
            Icon(
              Icons.celebration_outlined,
              color: context.moniaryColors.primary,
            ),
        ],
      ),
    );
  }
}

class _TransactionFeedCard extends ConsumerWidget {
  const _TransactionFeedCard({
    required this.transaction,
    required this.groupId,
  });

  final GroupTransaction transaction;
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(
    onTap: () => context.push(
      GroupRoutePaths.transactionDetail(
        groupId: groupId,
        transactionId: transaction.id,
      ),
    ),
    borderRadius: BorderRadius.circular(18),
    child: MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SupabaseImage(
              imagePath: transaction.imagePath,
              width: 52,
              height: 52,
              fallbackIcon: Icons.receipt_long_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.caption ?? context.l10n.groupTransactionFallback,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.creatorName ?? context.l10n.groupMemberFallback,
                  style: context.moniaryTypography.metadata,
                ),
              ],
            ),
          ),
          Text(ref.formatAmount(transaction.totalAmount)),
        ],
      ),
    ),
  );
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({required this.post});

  final GroupCommunityPost post;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipOval(
        child: SupabaseImage(
          imagePath: post.authorAvatarPath,
          width: 38,
          height: 38,
          fallbackBuilder: (_) => _MemberAvatarFallback(
            label: post.authorName ?? context.l10n.groupMemberFallback,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.authorName ?? context.l10n.groupMemberFallback,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              context.l10n.groupCommunityPostText,
              style: context.moniaryTypography.metadata,
            ),
          ],
        ),
      ),
      const Icon(Icons.more_horiz_rounded),
    ],
  );
}

class _PostMediaGrid extends StatelessWidget {
  const _PostMediaGrid({required this.media});

  final List<GroupCommunityMedia> media;

  @override
  Widget build(BuildContext context) {
    final visible = media.take(4).toList(growable: false);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (_, index) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SupabaseImage(
          imagePath: visible[index].storagePath,
          fallbackIcon: Icons.photo_outlined,
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: ActionChip(
      label: Text('$emoji${count > 0 ? ' $count' : ''}'),
      onPressed: onTap,
      backgroundColor: selected
          ? context.moniaryColors.primary.withValues(alpha: 0.12)
          : null,
      side: BorderSide(color: context.moniaryColors.outline),
    ),
  );
}

class _CommunityComposerSheet extends StatefulWidget {
  const _CommunityComposerSheet();

  @override
  State<_CommunityComposerSheet> createState() =>
      _CommunityComposerSheetState();
}

class _CommunityComposerSheetState extends State<_CommunityComposerSheet> {
  final _contentController = TextEditingController();
  final _images = <XFile>[];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCommunityWriteUpdate,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.groupCommunityWriteUpdateHelp,
            style: TextStyle(color: context.moniaryColors.textDim),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: context.l10n.groupCommunityComposerHint,
              alignLabelWithHint: true,
            ),
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_images[index].path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () =>
                            setState(() => _images.removeAt(index)),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(context.l10n.groupCommunityPostPhoto),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _CommunityComposerResult(
                  action: _CommunityComposerAction.publish,
                  content: _contentController.text,
                  media: [
                    for (final image in _images)
                      GroupCommunityMediaDraft(localPath: image.path),
                  ],
                ),
              ),
              child: Text(context.l10n.groupCommunityPublish),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    setState(() {
      _images
        ..clear()
        ..addAll(images.take(6));
    });
  }
}

enum _CommunityCreationAction { post, poll, challenge }

enum _CommunityComposerAction { publish }

class _CommunityCreateActivitySheet extends StatelessWidget {
  const _CommunityCreateActivitySheet({required this.canCreateChallenge});

  final bool canCreateChallenge;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCommunityCreateActivity,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.groupCommunityCreateActivityHelp,
            style: TextStyle(color: context.moniaryColors.textDim),
          ),
          const SizedBox(height: 14),
          _ActivityCreationTile(
            icon: Icons.edit_note_rounded,
            title: context.l10n.groupCommunityWriteUpdate,
            description: context.l10n.groupCommunityWriteUpdateHelp,
            color: context.moniaryColors.primary,
            onTap: () => Navigator.pop(context, _CommunityCreationAction.post),
          ),
          const SizedBox(height: 10),
          _ActivityCreationTile(
            icon: Icons.poll_outlined,
            title: context.l10n.groupCommunityCreatePoll,
            description: context.l10n.groupCommunityCreatePollHelp,
            color: context.moniaryColors.primary,
            onTap: () => Navigator.pop(context, _CommunityCreationAction.poll),
          ),
          if (canCreateChallenge) ...[
            const SizedBox(height: 10),
            _ActivityCreationTile(
              icon: Icons.savings_outlined,
              title: context.l10n.groupCommunityCreateChallenge,
              description: context.l10n.groupCommunityCreateChallengeHelp,
              color: context.moniaryColors.success,
              onTap: () =>
                  Navigator.pop(context, _CommunityCreationAction.challenge),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ActivityCreationTile extends StatelessWidget {
  const _ActivityCreationTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Ink(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: context.moniaryColors.textDim),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _CommunityComposerResult {
  const _CommunityComposerResult({
    required this.action,
    this.content,
    this.media = const [],
  });

  final _CommunityComposerAction action;
  final String? content;
  final List<GroupCommunityMediaDraft> media;
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog({
    required this.challenge,
    required this.remainingText,
    required this.controller,
    required this.onCancel,
    required this.onSubmit,
  });

  final GroupSavingsChallenge challenge;
  final String remainingText;
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.groupCommunityContribute),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.challenge.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.groupCommunityContributionHelp(widget.remainingText),
            style: TextStyle(color: context.moniaryColors.textDim),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: widget.controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.groupCommunityContributionAmount,
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: widget.onCancel,
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(context.l10n.groupCommunityContribute),
      ),
    ],
  );

  void _submit() {
    final amount = int.tryParse(widget.controller.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _error = context.l10n.groupCommunityContributionInvalid);
      return;
    }
    widget.onSubmit();
  }
}

class _PollDialog extends StatefulWidget {
  const _PollDialog();

  @override
  State<_PollDialog> createState() => _PollDialogState();
}

class _PollDialogState extends State<_PollDialog> {
  final _title = TextEditingController();
  final _optionControllers = <TextEditingController>[];
  String? _error;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _optionControllers.addAll([
      TextEditingController(),
      TextEditingController(),
    ]);
  }

  @override
  void dispose() {
    _title.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.groupPollCreate),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCommunityStepOf(_step + 1, 3),
            style: context.moniaryTypography.metadataStrong,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildStep(context),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: context.moniaryColors.danger),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _step == 0
            ? () => Navigator.pop(context)
            : () => setState(() {
                _step--;
                _error = null;
              }),
        child: Text(
          _step == 0
              ? context.l10n.commonCancel
              : context.l10n.groupCommunityBack,
        ),
      ),
      FilledButton(
        onPressed: _next,
        child: Text(
          _step == 2
              ? context.l10n.commonCreate
              : context.l10n.groupCommunityNext,
        ),
      ),
    ],
  );

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return Column(
          key: const ValueKey('poll-question'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupCommunityPollCreateHelp,
              style: TextStyle(color: context.moniaryColors.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.groupPollQuestion,
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey('poll-options'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupPollOptionsHint,
              style: context.moniaryTypography.metadataStrong,
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < _optionControllers.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.l10n.groupCommunityPollOptionLabel(
                            index + 1,
                          ),
                          prefixIcon: const Icon(
                            Icons.radio_button_unchecked_rounded,
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        tooltip: context.l10n.groupCommunityPollRemoveOption,
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _optionControllers.length >= 6 ? null : _addOption,
                icon: const Icon(Icons.add_rounded),
                label: Text(context.l10n.groupCommunityPollAddOption),
              ),
            ),
            if (_optionControllers.length >= 6)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.groupCommunityPollMaxOptions,
                  style: context.moniaryTypography.metadata,
                ),
              ),
          ],
        );
      default:
        final options = _parsedOptions;
        return Column(
          key: const ValueKey('poll-preview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupCommunityPollPreview,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            MoniaryEditorialCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final option in options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }

  List<String> get _optionValues => _optionControllers
      .map((controller) => controller.text.trim())
      .toList(growable: false);

  List<String> get _parsedOptions =>
      _optionValues.where((item) => item.isNotEmpty).toList(growable: false);

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    final controller = _optionControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _next() {
    if (_step == 0) {
      if (_title.text.trim().isEmpty) {
        setState(() => _error = context.l10n.groupCommunityPollValidation);
        return;
      }
      setState(() {
        _error = null;
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      final values = _optionValues;
      final options = _parsedOptions;
      final hasEmptyOption = values.any((item) => item.isEmpty);
      final hasDuplicate = options.length != options.toSet().length;
      if (hasEmptyOption || options.length < 2 || hasDuplicate) {
        setState(() => _error = context.l10n.groupCommunityPollValidation);
        return;
      }
      setState(() {
        _error = null;
        _step = 2;
      });
      return;
    }
    Navigator.pop(context, (_title.text.trim(), _parsedOptions));
  }
}

class _ChallengeDialog extends ConsumerStatefulWidget {
  const _ChallengeDialog();

  @override
  ConsumerState<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends ConsumerState<_ChallengeDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String? _error;
  int _step = 0;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.groupChallengeCreate),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCommunityStepOf(_step + 1, 3),
            style: context.moniaryTypography.metadataStrong,
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _buildStep(context),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: context.moniaryColors.danger),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _step == 0
            ? () => Navigator.pop(context)
            : () => setState(() {
                _step--;
                _error = null;
              }),
        child: Text(
          _step == 0
              ? context.l10n.commonCancel
              : context.l10n.groupCommunityBack,
        ),
      ),
      FilledButton(
        onPressed: _next,
        child: Text(
          _step == 2
              ? context.l10n.commonCreate
              : context.l10n.groupCommunityNext,
        ),
      ),
    ],
  );

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return Column(
          key: const ValueKey('challenge-name'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupCommunityChallengeCreateHelp,
              style: TextStyle(color: context.moniaryColors.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.groupChallengeName,
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey('challenge-target'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.groupCommunityChallengeInstruction),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.groupChallengeTarget,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.groupCommunityChallengeDuration,
              style: context.moniaryTypography.metadata,
            ),
          ],
        );
      default:
        final amount = int.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
        return Column(
          key: const ValueKey('challenge-preview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupCommunityChallengePreview,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            MoniaryEditorialCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.groupCommunityChallengeSaved}: ${ref.formatAmount(amount)}',
                  ),
                  const SizedBox(height: 4),
                  Text(context.l10n.groupCommunityChallengeDuration),
                  const SizedBox(height: 4),
                  Text(context.l10n.groupCommunityChallengeMembers),
                ],
              ),
            ),
          ],
        );
    }
  }

  void _next() {
    if (_step == 0) {
      if (_title.text.trim().isEmpty) {
        setState(() => _error = context.l10n.groupCommunityChallengeValidation);
        return;
      }
      setState(() {
        _error = null;
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      final amount = int.tryParse(_amount.text.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        setState(() => _error = context.l10n.groupCommunityChallengeValidation);
        return;
      }
      setState(() {
        _error = null;
        _step = 2;
      });
      return;
    }
    final amount = int.tryParse(_amount.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    Navigator.pop(context, (_title.text.trim(), amount));
  }
}

class _GroupAvatarFallback extends StatelessWidget {
  const _GroupAvatarFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    color: context.moniaryColors.primary.withValues(alpha: 0.16),
    alignment: Alignment.center,
    child: Text(
      label.isEmpty ? '?' : label.characters.first.toUpperCase(),
      style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w800),
    ),
  );
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 13,
    backgroundColor: context.moniaryColors.backgroundSoft,
    child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase()),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
}
