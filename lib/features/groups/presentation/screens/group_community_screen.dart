import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/integer_money_input_formatter.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_community_feed.dart';
import '../../domain/entities/group_enums.dart';
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

enum _CommunityFilter { all, posts, polls, challenges }

class _GroupCommunityScreenState extends ConsumerState<GroupCommunityScreen> {
  _CommunityFilter _filter = _CommunityFilter.all;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(groupCommunityFeedProvider(widget.groupId));
    final detail = ref.watch(groupDetailProvider(widget.groupId)).asData?.value;
    final uploadProgress = ref.watch(groupMediaUploadProgressProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: SafeArea(
        child: Column(
          children: [
            if (uploadProgress?.groupId == widget.groupId &&
                uploadProgress!.total > 0)
              _CommunityUploadProgress(progress: uploadProgress),
            Expanded(
              child: feedAsync.when(
                loading: () => const _CommunityLoadingState(),
                error: (error, _) => _ErrorState(
                  message: userFriendlyMessage(context, error),
                  onRetry: () => ref
                      .read(groupCommunityFeedProvider(widget.groupId).notifier)
                      .refresh(),
                ),
                data: (feed) {
                  final filteredItems = _filteredItems(feed.items);
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(
                            groupCommunityFeedProvider(widget.groupId).notifier,
                          )
                          .refresh();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _CommunityTopBar(),
                                const SizedBox(height: 12),
                                if (detail != null) ...[
                                  _CommunityGroupHeader(detail: detail),
                                  const SizedBox(height: 12),
                                ],
                                _CommunityQuickActions(
                                  groupId: widget.groupId,
                                  canCreateChallenge:
                                      detail?.canCreateChallenge ?? false,
                                  onCreatePost: () =>
                                      _openPostComposer(context),
                                  onCreatePoll: () => _createPoll(context),
                                  onCreateChallenge: () =>
                                      _createChallenge(context),
                                ),
                                const SizedBox(height: 14),
                                _ComposerLauncher(
                                  onTap: () => _openPostComposer(context),
                                ),
                                const SizedBox(height: 14),
                                _FilterBar(
                                  filter: _filter,
                                  onChanged: (value) =>
                                      setState(() => _filter = value),
                                ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                        if (filteredItems.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyFeedState(
                              filter: _filter,
                              onCreate: () => _openPostComposer(context),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                return Padding(
                                  key: ValueKey(item.id),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _FeedItemCard(
                                    item: item,
                                    groupId: widget.groupId,
                                    onCommentPost: (post) =>
                                        _showComments(context, post),
                                    onVote: (poll, optionId) =>
                                        _votePoll(poll, optionId),
                                    onContribute: (challenge) =>
                                        _contributeToChallenge(
                                          context,
                                          challenge,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (feed.hasMore)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              child: OutlinedButton.icon(
                                onPressed: feed.isLoadingMore
                                    ? null
                                    : () => ref
                                          .read(
                                            groupCommunityFeedProvider(
                                              widget.groupId,
                                            ).notifier,
                                          )
                                          .loadMore(),
                                icon: feed.isLoadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more_outlined),
                                label: Text(
                                  feed.isLoadingMore
                                      ? context.l10n.commonLoading
                                      : context.l10n.groupCommunityLoadMore,
                                ),
                              ),
                            ),
                          )
                        else
                          const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
            case _CommunityFilter.posts:
              return item.type == GroupCommunityFeedItemType.post;
            case _CommunityFilter.polls:
              return item.type == GroupCommunityFeedItemType.poll;
            case _CommunityFilter.challenges:
              return item.type == GroupCommunityFeedItemType.challenge;
          }
        })
        .toList(growable: false);
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
    final result = await showDialog<_ChallengeDraft>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _ChallengeDialog(),
    );
    if (result == null || !context.mounted) return;
    final now = DateTime.now();
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createSavingsChallenge(
            groupId: widget.groupId,
            title: result.title,
            targetAmount: result.targetAmount,
            startDate: now,
            endDate: now.add(Duration(days: result.durationDays)),
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

  Future<void> _contributeToChallenge(
    BuildContext context,
    GroupSavingsChallenge challenge,
  ) async {
    final remainingAmount =
        (challenge.targetAmount - challenge.totalContributed).clamp(
          0,
          challenge.targetAmount,
        );
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => _ContributionDialog(
        challenge: challenge,
        remainingAmount: remainingAmount,
        remainingText: ref.formatAmount(remainingAmount),
        currencySymbol: ref.currencySymbol,
      ),
    );
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _CommunityCommentsSheet(groupId: widget.groupId, initialPost: post),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CommunityCommentsSheet extends ConsumerStatefulWidget {
  const _CommunityCommentsSheet({
    required this.groupId,
    required this.initialPost,
  });

  final String groupId;
  final GroupCommunityPost initialPost;

  @override
  ConsumerState<_CommunityCommentsSheet> createState() =>
      _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState
    extends ConsumerState<_CommunityCommentsSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(
      groupCommunityCommentsProvider(widget.initialPost.id),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.groupCommunityComment,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, _) => _ErrorState(
                    message: userFriendlyMessage(context, error),
                    onRetry: () => ref.invalidate(
                      groupCommunityCommentsProvider(widget.initialPost.id),
                    ),
                  ),
                  data: (page) => page.items.isEmpty
                      ? Center(
                          child: Text(
                            context.l10n.groupCommunityCommentEmpty,
                            style: TextStyle(
                              color: context.moniaryColors.textDim,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: page.items.length + (page.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            if (index == page.items.length) {
                              return OutlinedButton.icon(
                                onPressed: page.isLoadingMore
                                    ? null
                                    : () => ref
                                          .read(
                                            groupCommunityCommentsProvider(
                                              widget.initialPost.id,
                                            ).notifier,
                                          )
                                          .loadMore(),
                                icon: page.isLoadingMore
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more_outlined),
                                label: Text(
                                  page.isLoadingMore
                                      ? context.l10n.commonLoading
                                      : context.l10n.groupCommunityLoadMore,
                                ),
                              );
                            }
                            return _CommunityCommentRow(
                              groupId: widget.groupId,
                              comment: page.items[index],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: context.l10n.groupCommunityCommentHint,
                  errorText: _error,
                  suffixIcon: IconButton(
                    tooltip: context.l10n.groupCommunityComment,
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _isSending) {
      if (value.isEmpty) {
        setState(() => _error = context.l10n.groupCommunityCommentRequired);
      }
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .addCommunityPostComment(
            groupId: widget.groupId,
            postId: widget.initialPost.id,
            content: value,
          );
      if (!mounted) return;
      _controller.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userFriendlyMessage(context, error));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _CommunityCommentRow extends ConsumerWidget {
  const _CommunityCommentRow({required this.groupId, required this.comment});

  final String groupId;
  final GroupCommunityComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage =
        comment.userId == ref.watch(currentGroupUserIdProvider) ||
        (ref.watch(groupDetailProvider(groupId)).asData?.value.canManageGroup ??
            false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SupabaseImage(
          imagePath: comment.avatarPath,
          width: 32,
          height: 32,
          borderRadius: BorderRadius.circular(16),
          fallbackBuilder: (_) => _MemberAvatarFallback(
            label: comment.displayName ?? comment.userId,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.displayName ?? comment.userId,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(comment.content),
              const SizedBox(height: 3),
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatShortDate(comment.createdAt),
                style: context.moniaryTypography.metadata,
              ),
            ],
          ),
        ),
        if (canManage)
          PopupMenuButton<_CommentAction>(
            tooltip: context.l10n.groupCommunityCommentActions,
            icon: const Icon(Icons.more_horiz_outlined, size: 20),
            onSelected: (action) => _handleAction(context, ref, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _CommentAction.edit,
                child: Text(context.l10n.groupCommunityEditComment),
              ),
              PopupMenuItem(
                value: _CommentAction.delete,
                child: Text(context.l10n.groupCommunityDeleteComment),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _CommentAction action,
  ) async {
    if (action == _CommentAction.edit) {
      final controller = TextEditingController(text: comment.content);
      final content = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.groupCommunityEditComment),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: context.l10n.groupCommunityCommentHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      );
      controller.dispose();
      if (content == null || !context.mounted) return;
      try {
        await ref
            .read(groupActionControllerProvider.notifier)
            .updateCommunityPostComment(
              groupId: groupId,
              postId: comment.postId,
              commentId: comment.id,
              content: content,
            );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupCommunityDeleteComment),
        content: Text(context.l10n.groupCommunityDeleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .deleteCommunityPostComment(
            groupId: groupId,
            postId: comment.postId,
            commentId: comment.id,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

enum _CommentAction { edit, delete }

class _CommunityTopBar extends StatelessWidget {
  const _CommunityTopBar();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          context.l10n.groupCommunityTab,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _CommunityQuickActions extends StatelessWidget {
  const _CommunityQuickActions({
    required this.groupId,
    required this.canCreateChallenge,
    required this.onCreatePost,
    required this.onCreatePoll,
    required this.onCreateChallenge,
  });

  final String groupId;
  final bool canCreateChallenge;
  final VoidCallback onCreatePost;
  final VoidCallback onCreatePoll;
  final VoidCallback onCreateChallenge;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        context.l10n.groupCommunityWriteUpdate,
        Icons.edit_note_outlined,
        onCreatePost,
      ),
      (
        context.l10n.groupCommunityCreatePoll,
        Icons.poll_outlined,
        onCreatePoll,
      ),
      if (canCreateChallenge)
        (
          context.l10n.groupCommunityCreateChallenge,
          Icons.savings_outlined,
          onCreateChallenge,
        ),
      (
        context.l10n.groupCommunityAlbumAction,
        Icons.photo_library_outlined,
        () => context.push(GroupRoutePaths.album(groupId)),
      ),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return Semantics(
            button: true,
            label: action.$1,
            child: MoniaryPill(
              label: action.$1,
              leading: Icon(action.$2),
              onTap: action.$3,
            ),
          );
        },
      ),
    );
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
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Semantics(
      button: true,
      label: context.l10n.groupCommunityComposerHint,
      child: Material(
        color: colors.surface.withValues(alpha: 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    foregroundColor: colors.primary,
                    child: const Icon(Icons.person_outline, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.groupCommunityComposerHint,
                      style: TextStyle(color: colors.textDim),
                    ),
                  ),
                  Icon(Icons.add_circle_outline, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final _CommunityFilter filter;
  final ValueChanged<_CommunityFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (context.l10n.groupCommunityAllTab, _CommunityFilter.all),
      (context.l10n.groupCommunityPostTab, _CommunityFilter.posts),
      (context.l10n.groupCommunityPollTab, _CommunityFilter.polls),
      (context.l10n.groupCommunityChallengeTab, _CommunityFilter.challenges),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Semantics(
            button: true,
            selected: filter == item.$2,
            label: item.$1,
            child: MoniaryPill(
              label: item.$1,
              selected: filter == item.$2,
              onTap: () => onChanged(item.$2),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState({required this.filter, required this.onCreate});

  final _CommunityFilter filter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final message = filter == _CommunityFilter.all
        ? context.l10n.groupCommunityNoFeed
        : context.l10n.groupCommunityFilterEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 32, color: colors.textDim),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textDim),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_outlined),
              label: Text(context.l10n.groupCommunityCreateActivity),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItemCard extends ConsumerWidget {
  const _FeedItemCard({
    required this.item,
    required this.groupId,
    required this.onCommentPost,
    required this.onVote,
    required this.onContribute,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentGroupUserIdProvider);
    final canManage =
        post.authorUserId == currentUserId ||
        (ref.watch(groupDetailProvider(groupId)).asData?.value.canManageGroup ??
            false);
    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(
            post: post,
            trailing: canManage
                ? PopupMenuButton<_PostAction>(
                    tooltip: context.l10n.groupCommunityPostActions,
                    icon: const Icon(Icons.more_vert_outlined),
                    onSelected: (action) =>
                        _handlePostAction(context, ref, action),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _PostAction.edit,
                        child: Text(context.l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: _PostAction.delete,
                        child: Text(context.l10n.commonDelete),
                      ),
                    ],
                  )
                : null,
          ),
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
              for (final reaction in [
                (
                  '❤️',
                  Icons.favorite_outline,
                  context.l10n.groupCommunityReactionLove,
                ),
                (
                  '👍',
                  Icons.thumb_up_outlined,
                  context.l10n.groupCommunityReactionLike,
                ),
                (
                  '🎉',
                  Icons.celebration_outlined,
                  context.l10n.groupCommunityReactionCelebrate,
                ),
              ])
                _ReactionButton(
                  icon: reaction.$2,
                  label: reaction.$3,
                  count: _reactionCount(post.reactions, reaction.$1),
                  selected: _reactionSelected(post.reactions, reaction.$1),
                  onTap: () => ref
                      .read(groupActionControllerProvider.notifier)
                      .toggleCommunityPostReaction(
                        groupId: groupId,
                        postId: post.id,
                        emoji: reaction.$1,
                      ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => onComment(post),
                icon: const Icon(Icons.mode_comment_outlined, size: 16),
                label: Text('${post.commentCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handlePostAction(
    BuildContext context,
    WidgetRef ref,
    _PostAction action,
  ) async {
    if (action == _PostAction.edit) {
      final controller = TextEditingController(text: post.content ?? '');
      final content = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.groupCommunityEditPost),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: context.l10n.groupCommunityComposerHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      );
      controller.dispose();
      if (content == null || !context.mounted) return;
      try {
        await ref
            .read(groupActionControllerProvider.notifier)
            .updateCommunityPost(
              groupId: groupId,
              postId: post.id,
              content: content,
            );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupCommunityDeletePost),
        content: Text(context.l10n.groupCommunityDeletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .deleteCommunityPost(groupId: groupId, postId: post.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  int _reactionCount(List<GroupCommunityReactionSummary> items, String emoji) =>
      items
          .where((item) => item.emoji == emoji)
          .fold(0, (sum, item) => sum + item.count);

  bool _reactionSelected(
    List<GroupCommunityReactionSummary> items,
    String emoji,
  ) => items.any((item) => item.emoji == emoji && item.reactedByCurrentUser);
}

enum _PostAction { edit, delete }

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
  void initState() {
    super.initState();
    _selectedOptionId = widget.poll.selectedOptionId;
  }

  @override
  void didUpdateWidget(covariant _PollFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.selectedOptionId != widget.poll.selectedOptionId) {
      _selectedOptionId = widget.poll.selectedOptionId;
    }
  }

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
    final hasVoted = poll.selectedOptionId != null;

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
                onTap: poll.isClosed || _isVoting || hasVoted
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
                                ? Icons.radio_button_checked_outlined
                                : Icons.radio_button_unchecked_outlined,
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
              onPressed:
                  poll.isClosed ||
                      _selectedOptionId == null ||
                      _isVoting ||
                      hasVoted
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
                          ? Icons.check_circle_outline
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
              Icons.check_outlined,
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
    child: Semantics(
      button: true,
      label: context.l10n.groupCommunityOpenExpense,
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
                    transaction.caption ??
                        context.l10n.groupTransactionFallback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.creatorName ?? context.l10n.groupMemberFallback,
                    style: context.moniaryTypography.metadata,
                  ),
                  const SizedBox(height: 6),
                  _TransactionStatusBadge(status: transaction.splitStatus),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ref.formatAmount(transaction.totalAmount),
              style: context.moniaryTypography.metadataStrong,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({required this.post, this.trailing});

  final GroupCommunityPost post;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipOval(
        child: SupabaseImage(
          imagePath: post.authorAvatarPath,
          width: 38,
          height: 38,
          cacheWidth: 96,
          cacheHeight: 96,
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
              '${context.l10n.groupCommunityPostText} · ${MaterialLocalizations.of(context).formatShortDate(post.createdAt)}',
              style: context.moniaryTypography.metadata,
            ),
          ],
        ),
      ),
      ?trailing,
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
          cacheWidth: 800,
          fallbackIcon: Icons.photo_outlined,
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Semantics(
        button: true,
        label: count > 0 ? '$label, $count' : label,
        selected: selected,
        child: ActionChip(
          avatar: Icon(icon, size: 17),
          label: Text(count > 0 ? '$count' : ''),
          onPressed: onTap,
          backgroundColor: selected
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surface,
          side: BorderSide(color: colors.outline),
          labelStyle: TextStyle(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TransactionStatusBadge extends StatelessWidget {
  const _TransactionStatusBadge({required this.status});

  final GroupSplitStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final (label, color) = switch (status) {
      GroupSplitStatus.posted => (
        context.l10n.groupTransactionPostedStatus,
        colors.success,
      ),
      GroupSplitStatus.amountMismatch => (
        context.l10n.groupTransactionMismatchStatus,
        colors.danger,
      ),
      GroupSplitStatus.pendingMemberAmountInput => (
        context.l10n.groupTransactionPendingShort,
        colors.warning,
      ),
      _ => (context.l10n.groupTransactionPendingShort, colors.textDim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: color,
          fontSize: 9,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
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
  String? _error;

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
      child: SingleChildScrollView(
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
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: context.l10n.groupCommunityComposerHint,
                alignLabelWithHint: true,
                errorText: _error,
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
                          tooltip: context.l10n.commonDelete,
                          onPressed: () =>
                              setState(() => _images.removeAt(index)),
                          icon: Icon(
                            Icons.close_outlined,
                            color: context.moniaryColors.surfaceRaised,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _images.length >= 6 ? null : _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                context.l10n.groupCommunityPhotoCount(_images.length),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(context.l10n.groupCommunityPublish),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _submit() {
    if (_contentController.text.trim().isEmpty && _images.isEmpty) {
      setState(() => _error = context.l10n.groupCommunityPostEmpty);
      return;
    }
    Navigator.pop(
      context,
      _CommunityComposerResult(
        action: _CommunityComposerAction.publish,
        content: _contentController.text.trim(),
        media: [
          for (final image in _images)
            GroupCommunityMediaDraft(localPath: image.path),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (!mounted) return;
    setState(() {
      final available = 6 - _images.length;
      _images.addAll(images.take(available));
      _error = null;
    });
  }
}

class _CommunityUploadProgress extends StatelessWidget {
  const _CommunityUploadProgress({required this.progress});

  final GroupMediaUploadProgress progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.groupCommunityUploadProgress(
              progress.completed,
              progress.total,
            ),
            style: context.moniaryTypography.metadataStrong,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress.fraction),
        ],
      ),
    );
  }
}

enum _CommunityComposerAction { publish }

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
    required this.remainingAmount,
    required this.remainingText,
    required this.currencySymbol,
  });

  final GroupSavingsChallenge challenge;
  final int remainingAmount;
  final String remainingText;
  final String currencySymbol;

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              IntegerMoneyInputFormatter(
                locale: Localizations.localeOf(context).toString(),
              ),
            ],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: context.l10n.groupCommunityContributionAmount,
              suffixText: widget.currencySymbol,
              helperText: context.l10n.groupCommunityContributionLimit(
                widget.remainingText,
              ),
              errorText: _error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(context.l10n.groupCommunityContribute),
      ),
    ],
  );

  void _submit() {
    final amount = parseIntegerMoney(_controller.text);
    if (amount <= 0) {
      setState(() => _error = context.l10n.groupCommunityContributionInvalid);
      return;
    }
    if (amount > widget.remainingAmount) {
      setState(
        () => _error = context.l10n.groupCommunityContributionTooHigh(
          widget.remainingText,
        ),
      );
      return;
    }
    Navigator.pop(context, amount);
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
                            Icons.radio_button_unchecked_outlined,
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
                icon: const Icon(Icons.add_outlined),
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

class _ChallengeDraft {
  const _ChallengeDraft({
    required this.title,
    required this.targetAmount,
    required this.durationDays,
  });

  final String title;
  final int targetAmount;
  final int durationDays;
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
  int _durationDays = 30;

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
              textInputAction: TextInputAction.done,
              inputFormatters: [
                IntegerMoneyInputFormatter(
                  locale: Localizations.localeOf(context).toString(),
                ),
              ],
              decoration: InputDecoration(
                labelText: context.l10n.groupChallengeTarget,
                suffixText: ref.currencySymbol,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.groupCommunityChallengeDuration,
              style: context.moniaryTypography.metadata,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in const [30, 60, 90])
                  ChoiceChip(
                    label: Text(context.l10n.groupCommunityDurationDays(days)),
                    selected: _durationDays == days,
                    onSelected: (_) => setState(() => _durationDays = days),
                  ),
              ],
            ),
          ],
        );
      default:
        final amount = parseIntegerMoney(_amount.text);
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
                  Text(
                    '${context.l10n.groupCommunityChallengeEnds}: '
                    '${MaterialLocalizations.of(context).formatShortDate(DateTime.now().add(Duration(days: _durationDays)))}',
                  ),
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
      final amount = parseIntegerMoney(_amount.text);
      if (amount <= 0) {
        setState(() => _error = context.l10n.groupCommunityChallengeValidation);
        return;
      }
      setState(() {
        _error = null;
        _step = 2;
      });
      return;
    }
    final amount = parseIntegerMoney(_amount.text);
    if (amount <= 0) return;
    Navigator.pop(
      context,
      _ChallengeDraft(
        title: _title.text.trim(),
        targetAmount: amount,
        durationDays: _durationDays,
      ),
    );
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

class _CommunityLoadingState extends StatelessWidget {
  const _CommunityLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          children: [
            Expanded(child: _LoadingLine(width: 120, color: colors.outline)),
            _LoadingLine(width: 36, color: colors.outline),
            const SizedBox(width: 8),
            _LoadingLine(width: 36, color: colors.outline),
          ],
        ),
        const SizedBox(height: 20),
        MoniaryEditorialCard(
          child: Row(
            children: [
              _LoadingLine(width: 64, height: 64, color: colors.outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LoadingLine(width: 160, color: colors.outline),
                    const SizedBox(height: 8),
                    _LoadingLine(width: 96, color: colors.outline),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < 3; index++) ...[
          MoniaryEditorialCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LoadingLine(width: 38, height: 38, color: colors.outline),
                    const SizedBox(width: 10),
                    _LoadingLine(width: 128, color: colors.outline),
                  ],
                ),
                const SizedBox(height: 14),
                _LoadingLine(width: double.infinity, color: colors.outline),
                const SizedBox(height: 8),
                _LoadingLine(width: 190, color: colors.outline),
              ],
            ),
          ),
          if (index < 2) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({
    required this.width,
    required this.color,
    this.height = 12,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}
