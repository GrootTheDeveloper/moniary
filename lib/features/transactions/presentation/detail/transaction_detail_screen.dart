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
      transactionByIdProvider(args.transactionId),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        actions: [
          transactionAsync.when(
            data: (transaction) => IconButton(
              icon: Icon(
                transaction.isImportant ? Icons.star : Icons.star_border,
                color: transaction.isImportant ? Colors.amber : Colors.grey,
              ),
              onPressed: () async {
                final repo = ref.read(transactionRepositoryProvider);
                final nextVal = !transaction.isImportant;
                await repo.toggleTransactionImportance(transaction.id, nextVal);

                // Refresh local cache
                ref.invalidate(transactionByIdProvider(args.transactionId));

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
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) =>
            _TransactionDetailBody(transaction: transaction, day: args.day),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.transactionLoadDetailError(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailBody extends ConsumerWidget {
  const _TransactionDetailBody({required this.transaction, required this.day});

  final TransactionEntry transaction;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? AppTheme.success : AppTheme.amber,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withValues(alpha: 0.92), const Color(0xFF151F2B)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SupabaseImage(
                imagePath: transaction.imagePath,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(28),
                fallbackIcon: Icons.local_offer_outlined,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF151F2B).withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: transaction.isIncome
                          ? AppTheme.success
                          : AppTheme.danger,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 10,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    transaction.note?.trim().isNotEmpty == true
                        ? transaction.note!.trim()
                        : transaction.categoryName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 10,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat(
                      'dd MMMM yyyy • HH:mm',
                      Localizations.localeOf(context).toString(),
                    ).format(transaction.transactionDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      shadows: [
                        const Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          child: Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: context.l10n.transactionCategory,
                  value: transaction.categoryName,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoItem(
                  label: context.l10n.transactionWallet,
                  value: transaction.walletName,
                  color: AppColor.fromHex(
                    transaction.walletColor,
                    fallback: AppTheme.mint,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.transactionNote,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                transaction.note?.trim().isNotEmpty == true
                    ? transaction.note!.trim()
                    : context.l10n.transactionNoteEmpty,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await showTransactionFormSheet(
                    context,
                    ref,
                    initialTransaction: transaction,
                  );
                  if (result == null || !context.mounted) return;
                  context.pop(result);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.commonEdit),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: Text(context.l10n.transactionDeleteTitleQuestion),
                      content: Text(context.l10n.transactionDeleteUndone),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(context.l10n.commonCancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
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
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(context.l10n.commonDelete),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: child,
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
