import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/composer/transaction_composer_controller.dart';
import '../../application/queries/transaction_queries.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../form/transaction_form_sheet.dart';
import 'transaction_route_args.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.args, super.key});

  static const routePath = '/transaction-detail';

  final TransactionDetailRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(
      transactionByIdProvider(args.transaction.id),
    );
    final transaction = transactionAsync.value ?? args.transaction;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(context.l10n.transactionDetailTitle),
        actions: [
          IconButton(
            icon: Icon(
              transaction.isImportant ? Icons.star : Icons.star_border,
              color: transaction.isImportant
                  ? AppTheme.amber
                  : context.moniaryColors.textDim,
            ),
            onPressed: () async {
              await ref
                  .read(transactionComposerProvider.notifier)
                  .toggleImportance(
                    transaction.id,
                    !transaction.isImportant,
                    transaction.transactionDate,
                  );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _TransactionDetailBody(transaction: transaction),
    );
  }
}

class _TransactionDetailBody extends ConsumerWidget {
  const _TransactionDetailBody({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final typography = context.moniaryTypography;
    final locale = Localizations.localeOf(context).toString();
    final categoryColor = AppColor.fromHex(
      transaction.categoryColor,
      fallback: transaction.isIncome ? colors.success : colors.warning,
    );
    final note = transaction.note?.trim();
    final title = note?.isNotEmpty == true ? note! : transaction.categoryName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.outline),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'tx_image_${transaction.id}',
                    child: SupabaseImage(
                      imagePath: transaction.imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.receipt_long_outlined,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.82),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.62],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'HH:mm · EEEE, d MMMM',
                            locale,
                          ).format(transaction.transactionDate).toUpperCase(),
                          style: typography.metadataStrong.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ObscurableAmountText(
                          amountText: formatVnd(transaction.amount),
                          prefixText: transaction.isIncome ? '+' : '-',
                          style: typography.displayMedium.copyWith(
                            color: transaction.isIncome
                                ? colors.success
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (transaction.isImportant)
                    Positioned(
                      top: 18,
                      right: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(Icons.star, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outline),
          ),
          child: Column(
            children: [
              _DetailMetaRow(
                label: context.l10n.transactionWallet,
                value: transaction.walletName,
              ),
              _DetailMetaRow(
                label: context.l10n.transactionCategory,
                value: transaction.categoryName,
                indicatorColor: categoryColor,
              ),
              _DetailMetaRow(
                label: context.l10n.transactionDate,
                value: DateFormat(
                  'd/M/y · HH:mm',
                  locale,
                ).format(transaction.transactionDate),
              ),
              _DetailMetaRow(
                label: context.l10n.transactionSource,
                value: transaction.imagePath == null
                    ? context.l10n.transactionSourceManual
                    : context.l10n.transactionSourceReceiptImage,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _editTransaction(context, ref),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.commonEdit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteTransaction(context, ref),
                icon: Icon(Icons.delete_outline, color: colors.danger),
                label: Text(
                  context.l10n.commonDelete,
                  style: TextStyle(color: colors.danger),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editTransaction(BuildContext context, WidgetRef ref) async {
    final result = await showTransactionFormSheet(
      context,
      ref,
      initialTransaction: transaction,
    );
    if (result == null || !context.mounted) return;
    context.pop(result);
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.moniaryColors.surface,
        title: Text(context.l10n.transactionDeleteTitleQuestion),
        content: Text(context.l10n.transactionDeleteUndone),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(transactionComposerProvider.notifier)
        .deleteTransaction(transaction.id);
    if (!context.mounted) return;
    context.pop(
      TransactionMutationResult(
        previousDate: transaction.transactionDate,
        currentDate: null,
      ),
    );
  }
}

class _DetailMetaRow extends StatelessWidget {
  const _DetailMetaRow({
    required this.label,
    required this.value,
    this.indicatorColor,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color? indicatorColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.outline))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textDim,
                ),
              ),
              const Spacer(),
              if (indicatorColor != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
