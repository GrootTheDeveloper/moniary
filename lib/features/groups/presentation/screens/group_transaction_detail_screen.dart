import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import '../widgets/comment_list.dart';
import 'add_group_transaction_screen.dart';
import 'member_amount_input_screen.dart';

class GroupTransactionDetailScreen extends ConsumerStatefulWidget {
  const GroupTransactionDetailScreen({required this.transactionId, super.key});

  static const routePath = '/groups/transaction/detail';

  final String transactionId;

  @override
  ConsumerState<GroupTransactionDetailScreen> createState() =>
      _GroupTransactionDetailScreenState();
}

class _GroupTransactionDetailScreenState
    extends ConsumerState<GroupTransactionDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      groupTransactionDetailProvider(widget.transactionId),
    );
    final currentUserId = ref.watch(currentGroupUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupTransactionDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (detail) {
          final transaction = detail.transaction;
          final isCreator = transaction.createdBy == currentUserId;
          final ownShare = detail.shares.where(
            (share) => share.userId == currentUserId,
          );
          final needsAmountInput =
              transaction.splitMode == GroupSplitMode.unequal &&
              transaction.splitStatus != GroupSplitStatus.posted &&
              ownShare.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              if (transaction.imagePath != null)
                AspectRatio(
                  aspectRatio: 1,
                  child: SupabaseImage(
                    imagePath: transaction.imagePath,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              if (transaction.imagePath != null ||
                  transaction.imageUploadStatus ==
                      GroupImageUploadStatus.failed)
                const SizedBox(height: 18),
              if (transaction.imageUploadStatus ==
                  GroupImageUploadStatus.failed)
                _ImageUploadFailureNotice(
                  canRetry: isCreator,
                  onRetry: () => _openEdit(detail),
                ),
              if (transaction.imageUploadStatus ==
                  GroupImageUploadStatus.failed)
                const SizedBox(height: 18),
              Text(
                transaction.caption?.isNotEmpty == true
                    ? transaction.caption!
                    : transaction.categoryName ?? context.l10n.groupNoCategory,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                ref.formatAmount(transaction.totalAmount),
                style: const TextStyle(
                  color: AppTheme.mintSoft,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (transaction.note?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(transaction.note!),
              ],
              const SizedBox(height: 14),
              _ReactionRow(transactionId: transaction.id),
              const SizedBox(height: 18),
              _InfoRow(
                label: context.l10n.groupTransactionCreator,
                value:
                    transaction.creatorName ?? context.l10n.groupUnknownMember,
              ),
              _InfoRow(
                label: context.l10n.groupSplitModeTitle,
                value: switch (transaction.splitMode) {
                  GroupSplitMode.equal => context.l10n.groupSplitEqual,
                  GroupSplitMode.exact => context.l10n.groupSplitExact,
                  GroupSplitMode.unequal => context.l10n.groupSplitUnequal,
                },
              ),
              _InfoRow(
                label: context.l10n.groupPaymentModeTitle,
                value: _paymentModeLabel(context, transaction.paymentMode),
              ),
              if (needsAmountInput) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => context.push(
                    MemberAmountInputScreen.routePath,
                    extra: MemberAmountInputArgs(
                      groupId: transaction.groupId,
                      transactionId: transaction.id,
                      initialAmount: ownShare.first.shareAmount,
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_outlined),
                  label: Text(context.l10n.groupAmountInputTitle),
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.splitStatus == GroupSplitStatus.amountMismatch
                      ? context.l10n.groupTransactionAmountMismatch
                      : context.l10n.groupTransactionMembersPending,
                  style: const TextStyle(color: AppTheme.amber),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.groupTransactionPayers,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...detail.payers.map(
                (payer) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(
                    payer.displayName ?? context.l10n.groupUnknownMember,
                  ),
                  trailing: Text(ref.formatAmount(payer.paidAmount)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.groupTransactionShares,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...detail.shares.map((share) {
                final paid = detail.payers
                    .where((payer) => payer.userId == share.userId)
                    .fold<int>(0, (sum, payer) => sum + payer.paidAmount);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.pie_chart_outline),
                  title: Text(
                    share.displayName ?? context.l10n.groupUnknownMember,
                  ),
                  subtitle: Text(
                    context.l10n.groupSharePaidBalance(
                      ref.formatAmount(share.shareAmount),
                      ref.formatAmount(paid),
                      ref.formatAmount(share.shareAmount - paid),
                    ),
                  ),
                );
              }),
              if (isCreator) ...[
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openEdit(detail),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(context.l10n.commonEdit),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _delete(detail),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.l10n.commonDelete),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              Text(
                context.l10n.groupCommentsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (detail.comments.isEmpty)
                Text(context.l10n.groupCommentsEmpty)
              else
                CommentList(
                  comments: detail.comments,
                  currentUserId: currentUserId,
                  onEdit: _editComment,
                  onDelete: _deleteComment,
                ),
              const SizedBox(height: 10),
              const Text(
                'Dùng @username để nhắc thành viên trong nhóm.',
                style: TextStyle(color: AppTheme.textSubtle),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: context.l10n.groupCommentHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendComment,
                    tooltip: context.l10n.groupCommentSend,
                    icon: const Icon(Icons.send_outlined),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEdit(GroupTransactionDetail detail) {
    return context.push(
      AddGroupTransactionScreen.routePath,
      extra: AddGroupTransactionArgs(
        groupId: detail.transaction.groupId,
        initialDetail: detail,
      ),
    );
  }

  String _paymentModeLabel(BuildContext context, GroupPaymentMode mode) =>
      switch (mode) {
        GroupPaymentMode.everyonePaid => context.l10n.groupPaymentEveryone,
        GroupPaymentMode.singlePayer => context.l10n.groupPaymentSingle,
        GroupPaymentMode.multiplePayers => context.l10n.groupPaymentMultiple,
      };

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupCommentRequired)),
      );
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .addComment(
            transactionId: widget.transactionId,
            content: _commentController.text,
          );
      if (!mounted) return;
      _commentController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _editComment(GroupTransactionComment comment) async {
    final controller = TextEditingController(text: comment.content);
    final commentRequiredMessage = context.l10n.groupCommentRequired;
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.commonEdit),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(hintText: context.l10n.groupCommentHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = content?.trim();
    if (trimmed == null) return;
    if (trimmed.isEmpty) {
      _showMessage(commentRequiredMessage);
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateComment(
            commentId: comment.id,
            transactionId: widget.transactionId,
            content: trimmed,
          );
    } catch (error) {
      if (!mounted) return;
      _showMessage(userFriendlyMessage(context, error));
    }
  }

  Future<void> _deleteComment(GroupTransactionComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.l10n.groupCommentDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .deleteComment(
            commentId: comment.id,
            transactionId: widget.transactionId,
          );
    } catch (error) {
      if (!mounted) return;
      _showMessage(userFriendlyMessage(context, error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(GroupTransactionDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.l10n.groupTransactionDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .deleteTransaction(
            transactionId: detail.transaction.id,
            groupId: detail.transaction.groupId,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _ReactionRow extends ConsumerWidget {
  const _ReactionRow({required this.transactionId});

  final String transactionId;

  static const _quickEmojis = ['👍', '❤️', '😂', '😮', '🎉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(groupReactionsProvider(transactionId));
    final reactions = reactionsAsync.asData?.value ?? const [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final reaction in reactions)
          _ReactionChip(
            transactionId: transactionId,
            emoji: reaction.emoji,
            count: reaction.count,
            selected: reaction.reactedByCurrentUser,
          ),
        _AddReactionButton(transactionId: transactionId),
      ],
    );
  }
}

class _ReactionChip extends ConsumerWidget {
  const _ReactionChip({
    required this.transactionId,
    required this.emoji,
    required this.count,
    required this.selected,
  });

  final String transactionId;
  final String emoji;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Material(
      color: selected
          ? AppTheme.mintSoft.withValues(alpha: 0.18)
          : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => ref
            .read(groupActionControllerProvider.notifier)
            .toggleReaction(transactionId: transactionId, emoji: emoji),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.mintSoft : colors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.mintSoft : colors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddReactionButton extends ConsumerWidget {
  const _AddReactionButton({required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showEmojiPicker(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outline),
          ),
          child: Icon(
            Icons.add_reaction_outlined,
            size: 16,
            color: colors.textDim,
          ),
        ),
      ),
    );
  }

  Future<void> _showEmojiPicker(BuildContext context, WidgetRef ref) async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _EmojiPickerSheet(emojis: _ReactionRow._quickEmojis),
    );
    if (emoji == null) return;
    if (!context.mounted) return;
    await ref
        .read(groupActionControllerProvider.notifier)
        .toggleReaction(transactionId: transactionId, emoji: emoji);
  }
}

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final emoji in emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.pop(context, emoji),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageUploadFailureNotice extends StatelessWidget {
  const _ImageUploadFailureNotice({
    required this.canRetry,
    required this.onRetry,
  });

  final bool canRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.groupTransactionImageUploadFailed,
              style: const TextStyle(color: AppTheme.amber),
            ),
          ),
          if (canRetry)
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
