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
import '../../../calendar/application/month/calendar_month_provider.dart';
import '../../../statistics/presentation/statistics_view.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../../domain/models/transaction_entry.dart';
import '../form/transaction_form_sheet.dart';
import 'transaction_detail_screen.dart';
import 'transaction_route_args.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({required this.date, super.key});

  static const routePath = '/day-detail';

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsForDayProvider(date));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              DateUtils.isSameDay(date, DateTime.now())
                  ? context.l10n.calendarToday
                  : DateFormat(
                      'EEEE, d/M',
                      Localizations.localeOf(context).toString(),
                    ).format(date),
            ),
            Text(
              DateFormat(
                'dd MMMM, yyyy',
                Localizations.localeOf(context).toString(),
              ).format(date),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) =>
            _DayDetailBody(date: date, transactions: transactions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.l10n.transactionLoadDayError(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.mint,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await showTransactionFormSheet(
            context,
            ref,
            initialDateTime: date,
          );
          if (result == null || !context.mounted) return;
          _applyMutation(ref, result);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayDetailBody extends ConsumerWidget {
  const _DayDetailBody({required this.date, required this.transactions});

  final DateTime date;
  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6 + (transactions.isEmpty ? 1 : transactions.length),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: context.l10n.transactionTotalIncome,
                  value: '+${formatVnd(income)}',
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: context.l10n.transactionTotalExpense,
                  value: '-${formatVnd(expense)}',
                  color: AppTheme.danger,
                ),
              ),
            ],
          );
        }
        if (index == 1) return const SizedBox(height: 12);
        if (index == 2) {
          return _SummaryCard(
            label: context.l10n.transactionNetTotal,
            value:
                '${income - expense >= 0 ? '+' : '-'}${formatVnd((income - expense).abs())}',
            color: income - expense >= 0 ? AppTheme.success : AppTheme.danger,
          );
        }
        if (index == 3) return const SizedBox(height: 18);
        if (index == 4) {
          return Row(
            children: [
              Text(
                context.l10n.transactionCount(transactions.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          );
        }
        if (index == 5) return const SizedBox(height: 12);

        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Text(
              context.l10n.transactionDayEmpty,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          );
        }

        final transaction = transactions[index - 6];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TransactionTile(
            transaction: transaction,
            onTap: () async {
              final result = await context.push<TransactionMutationResult>(
                TransactionDetailScreen.routePath,
                extra: TransactionDetailRouteArgs(
                  transactionId: transaction.id,
                  day: date,
                ),
              );
              if (result == null || !context.mounted) return;
              _applyMutation(ref, result);
            },
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onTap});

  final TransactionEntry transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? AppTheme.success : AppTheme.amber,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.42)],
                ),
              ),
              child: SupabaseImage(
                imagePath: transaction.imagePath,
                width: 54,
                height: 54,
                borderRadius: BorderRadius.circular(16),
                fallbackIcon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.note?.trim().isNotEmpty == true
                              ? transaction.note!.trim()
                              : transaction.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (transaction.isImportant) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(transaction.transactionDate),
                      ),
                      _MiniTag(label: transaction.categoryName, color: accent),
                      Text(transaction.walletName),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: transaction.isIncome
                    ? AppTheme.success
                    : AppTheme.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void _applyMutation(WidgetRef ref, TransactionMutationResult result) {
  final days = <DateTime>{
    if (result.previousDate != null)
      DateTime(
        result.previousDate!.year,
        result.previousDate!.month,
        result.previousDate!.day,
      ),
    if (result.currentDate != null)
      DateTime(
        result.currentDate!.year,
        result.currentDate!.month,
        result.currentDate!.day,
      ),
  };

  for (final day in days) {
    ref.invalidate(transactionsForDayProvider(day));
  }

  final months = <DateTime>{
    if (result.previousDate != null)
      DateTime(result.previousDate!.year, result.previousDate!.month, 1),
    if (result.currentDate != null)
      DateTime(result.currentDate!.year, result.currentDate!.month, 1),
  };

  for (final month in months) {
    ref.invalidate(calendarMonthProvider(month));
    ref.invalidate(statisticsMonthProvider(month));
  }
}
