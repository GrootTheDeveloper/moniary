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
              if (transaction.imagePath != null) const SizedBox(height: 18),
              Text(
                transaction.caption?.isNotEmpty == true
                    ? transaction.caption!
                    : transaction.categoryName ?? context.l10n.groupNoCategory,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                formatVnd(transaction.totalAmount, locale: Localizations.localeOf(context).toString()),
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
                  trailing: Text(formatVnd(payer.paidAmount, locale: Localizations.localeOf(context).toString())),
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
                      formatVnd(share.shareAmount, locale: Localizations.localeOf(context).toString()),
                      formatVnd(paid, locale: Localizations.localeOf(context).toString()),
                      formatVnd(share.shareAmount - paid, locale: Localizations.localeOf(context).toString()),
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
                        onPressed: () => context.push(
                          AddGroupTransactionScreen.routePath,
                          extra: AddGroupTransactionArgs(
                            groupId: transaction.groupId,
                            initialDetail: detail,
                          ),
                        ),
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
                ...detail.comments.map(
                  (comment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceRaised,
                      child: const Icon(Icons.person_outline),
                    ),
                    title: Text(
                      comment.displayName ?? context.l10n.groupUnknownMember,
                    ),
                    subtitle: Text(comment.content),
                  ),
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
