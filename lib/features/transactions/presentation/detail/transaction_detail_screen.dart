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
      backgroundColor: context.moniaryColors.background,
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

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
            children: [
              Row(
                children: [
                  _DetailTopButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.transactionDetailTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: typography.metadataStrong.copyWith(
                        color: colors.textDim,
                        fontSize: 8.8,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  _DetailTopButton(
                    icon: transaction.isImportant
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    tooltip: context.l10n.starredTransactionsTitle,
                    isActive: transaction.isImportant,
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
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 298,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: colors.textPrimary.withValues(alpha: 0.11),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
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
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.72),
                                ],
                                stops: const [0, 0.46, 1],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 17,
                          top: 16,
                          right: 17,
                          child: Text(
                            DateFormat(
                              'HH:mm · EEEE, d MMMM',
                              locale,
                            ).format(transaction.transactionDate).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.metadataStrong.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 8.8,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 17,
                          right: 17,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ObscurableAmountText(
                                amountText: formatVnd(transaction.amount),
                                prefixText: transaction.isIncome ? '+' : '-',
                                style: typography.displayMedium.copyWith(
                                  color: transaction.isIncome
                                      ? colors.success
                                      : Colors.white,
                                  fontSize: 37,
                                  height: 0.96,
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 11),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _HeroTag(label: transaction.categoryName),
                                  _HeroTag(
                                    label: transaction.imagePath == null
                                        ? context.l10n.transactionSourceManual
                                        : context
                                              .l10n
                                              .transactionSourceReceiptImage,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 21),
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
                label: context.l10n.transactionSource,
                value: transaction.imagePath == null
                    ? context.l10n.transactionSourceManual
                    : context.l10n.transactionSourceReceiptImage,
                showDivider: false,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DetailActionButton(
                      label: context.l10n.commonEdit,
                      onPressed: () => _editTransaction(context, ref),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DetailActionButton(
                      label: context.l10n.commonDelete,
                      foregroundColor: colors.danger,
                      backgroundColor: colors.danger.withValues(alpha: 0.06),
                      borderColor: colors.danger.withValues(alpha: 0.32),
                      onPressed: () => _deleteTransaction(context, ref),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

class _DetailTopButton extends StatelessWidget {
  const _DetailTopButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface.withValues(alpha: 0.56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: isActive
                ? colors.primary.withValues(alpha: 0.46)
                : colors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 37,
            height: 37,
            child: Icon(
              icon,
              size: 18,
              color: isActive ? colors.primary : colors.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.label,
    required this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final textColor = foregroundColor ?? colors.textPrimary;
    return Material(
      color: backgroundColor ?? colors.surface.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor ?? colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
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
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: colors.outline.withValues(alpha: 0.78),
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textDim,
                  fontSize: 8.8,
                  letterSpacing: 1.55,
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
                    fontSize: 13.2,
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
