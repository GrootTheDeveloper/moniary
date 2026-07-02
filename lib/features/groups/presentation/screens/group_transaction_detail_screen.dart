import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
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
                formatVnd(transaction.totalAmount),
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
              const SizedBox(height: 18),
              _InfoRow(
                label: context.l10n.groupTransactionCreator,
                value:
                    transaction.creatorName ?? context.l10n.groupUnknownMember,
              ),
              _InfoRow(
                label: context.l10n.groupSplitModeTitle,
                value: transaction.splitMode == GroupSplitMode.equal
                    ? context.l10n.groupSplitEqual
                    : context.l10n.groupSplitUnequal,
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
                  trailing: Text(formatVnd(payer.paidAmount)),
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
                      formatVnd(share.shareAmount),
                      formatVnd(paid),
                      formatVnd(share.shareAmount - paid),
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
              const SizedBox(height: 24),
              _ReactionBar(
                groupId: transaction.groupId,
                transactionId: transaction.id,
              ),
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

class _ReactionBar extends ConsumerWidget {
  const _ReactionBar({required this.groupId, required this.transactionId});

  static const _emojis = ['👍', '❤️', '😂', '🙌', '😮'];

  final String groupId;
  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reactionsAsync = ref.watch(
      groupTransactionReactionsProvider(transactionId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reaction', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        reactionsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Không tải được reaction.'),
          data: (reactions) {
            final byEmoji = {for (final item in reactions) item.emoji: item};
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((emoji) {
                final summary = byEmoji[emoji];
                final selected = summary?.reactedByCurrentUser ?? false;
                final count = summary?.count ?? 0;
                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  label: Text('$emoji $count'),
                  onSelected: (_) => ref
                      .read(groupActionControllerProvider.notifier)
                      .toggleReaction(
                        transactionId: transactionId,
                        groupId: groupId,
                        emoji: emoji,
                      ),
                );
              }).toList(),
            );
          },
        ),
      ],
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
