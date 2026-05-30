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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  label: context.l10n.transactionNetTotal,
                  value:
                      '${income - expense >= 0 ? '+' : '-'}${formatVnd((income - expense).abs())}',
                  color: income - expense >= 0
                      ? AppTheme.success
                      : AppTheme.danger,
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.transactionCount(transactions.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Container(
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
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final transaction = transactions[index];
                return TransactionGridTile(
                  transaction: transaction,
                  onTap: () async {
                    final result = await context
                        .push<TransactionMutationResult>(
                          TransactionDetailScreen.routePath,
                          extra: TransactionDetailRouteArgs(
                            transactionId: transaction.id,
                            day: date,
                          ),
                        );
                    if (result == null || !context.mounted) return;
                    _applyMutation(ref, result);
                  },
                );
              }, childCount: transactions.length),
            ),
          ),
      ],
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

class TransactionGridTile extends StatelessWidget {
  const TransactionGridTile({required this.transaction, required this.onTap});

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
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.42)],
                ),
              ),
              child: SupabaseImage(
                imagePath: transaction.imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                fallbackIcon: Icons.receipt_long_outlined,
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridTag(label: transaction.categoryName),
                  const SizedBox(height: 4),
                  GridTag(label: transaction.walletName),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.black54,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (transaction.isImportant) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppTheme.amber, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridTag extends StatelessWidget {
  const GridTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
