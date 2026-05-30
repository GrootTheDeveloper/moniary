import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../application/queries/transaction_queries.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../calendar/application/month/calendar_month_provider.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../../domain/models/transaction_entry.dart';
import '../../application/composer/transaction_composer_controller.dart';
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
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  transaction.isImportant ? Icons.star : Icons.star_border,
                  color: transaction.isImportant ? Colors.amber : Colors.grey,
                ),
                onPressed: () async {
                  final repo = ref.read(transactionRepositoryProvider);
                  final nextVal = !transaction.isImportant;
                  await repo.toggleTransactionImportance(
                    transaction.id,
                    nextVal,
                  );

                  // Refresh local cache
                  ref.invalidate(transactionByIdProvider(args.transaction.id));

                  // Invalidate day detail queries
                  final txDate = transaction.transactionDate;
                  final dayStart = DateTime(
                    txDate.year,
                    txDate.month,
                    txDate.day,
                  );
                  ref.invalidate(transactionsForDayProvider(dayStart));

                  // Invalidate calendar month queries
                  final monthStart = DateTime(txDate.year, txDate.month, 1);
                  ref.invalidate(calendarMonthProvider(monthStart));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await showTransactionFormSheet(
                      context,
                      ref,
                      initialTransaction: transaction,
                    );
                    if (result == null || !context.mounted) return;
                    context.pop(result);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: Text(
                          context.l10n.transactionDeleteTitleQuestion,
                        ),
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
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.commonEdit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outlined,
                          size: 20,
                          color: AppTheme.danger,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.commonDelete,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _TransactionDetailBody(transaction: transaction, day: args.day),
    );
  }
}

class _TransactionDetailBody extends ConsumerWidget {
  const _TransactionDetailBody({required this.transaction, required this.day});

  final TransactionEntry transaction;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = AppColor.fromHex(
      transaction.categoryColor,
      fallback: transaction.isIncome ? AppTheme.success : AppTheme.amber,
    );
    final walletColor = AppColor.fromHex(
      transaction.walletColor,
      fallback: AppTheme.mint,
    );

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
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

                    // Top Overlay: Date, Category and Wallet
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'dd MMMM yyyy • HH:mm',
                                Localizations.localeOf(context).toString(),
                              ).format(transaction.transactionDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: _TagPill(
                                    icon: Icons.category_outlined,
                                    label: transaction.categoryName,
                                    color: categoryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: _TagPill(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: transaction.walletName,
                                    color: walletColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Overlay: Amount, Note
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 24,
                          top: 64,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: transaction.isIncome
                                    ? AppTheme.success
                                    : Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (transaction.note?.trim().isNotEmpty == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  transaction.note!.trim(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              Text(
                                context.l10n.transactionNoteEmpty,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
