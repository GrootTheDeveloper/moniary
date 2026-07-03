import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/app_logger.dart';
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
        title: Text(
          DateUtils.isSameDay(date, DateTime.now())
              ? context.l10n.calendarToday
              : DateFormat(
                  'd/M',
                  Localizations.localeOf(context).toString(),
                ).format(date),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) =>
            _DayDetailBody(date: date, transactions: transactions),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load day transactions', error, stackTrace);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.transactionLoadDayError(
                  userFriendlyMessage(context, error),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
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
    final net = income - expense;
    final locale = Localizations.localeOf(context).toString();
    final colors = context.moniaryColors;
    final typography = context.moniaryTypography;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colors.outline),
                boxShadow: [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateUtils.isSameDay(date, DateTime.now())
                          ? context.l10n.calendarToday.toUpperCase()
                          : DateFormat(
                              'EEEE',
                              locale,
                            ).format(date).toUpperCase(),
                      style: typography.metadataStrong.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('EEEE, d MMMM', locale).format(date),
                      style: typography.displayMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${context.l10n.transactionCount(transactions.length).toUpperCase()} · '
                      '${net >= 0 ? '+' : '-'}${formatVnd(net.abs())}',
                      style: typography.metadataStrong.copyWith(
                        color: net >= 0 ? colors.success : colors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (transactions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _DayMetric(
                      label: context.l10n.transactionTotalIncome,
                      value: '+${formatVnd(income)}',
                      color: colors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DayMetric(
                      label: context.l10n.transactionTotalExpense,
                      value: '-${formatVnd(expense)}',
                      color: colors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (transactions.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outline),
                ),
                child: Text(
                  context.l10n.transactionDayEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            sliver: SliverList.separated(
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Divider(height: 1, color: colors.outline),
              ),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _DayTransactionRow(
                      transaction: transaction,
                      onTap: () async {
                        final result = await context
                            .push<TransactionMutationResult>(
                              TransactionDetailScreen.routePath,
                              extra: TransactionDetailRouteArgs(
                                transaction: transaction,
                                day: date,
                              ),
                            );
                        if (result == null || !context.mounted) return;
                        _applyMutation(ref, result);
                      },
                    )
                    .animate(delay: (30 * index).ms)
                    .fade()
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      curve: Curves.easeOutQuad,
                      duration: 300.ms,
                    );
              },
            ),
          ),
      ],
    );
  }
}

class _DayMetric extends StatelessWidget {
  const _DayMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: context.moniaryTypography.metadata,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTransactionRow extends StatelessWidget {
  const _DayTransactionRow({required this.transaction, required this.onTap});

  final TransactionEntry transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? colors.success : colors.warning,
    );
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : transaction.categoryName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: ColoredBox(
                      color: accent.withValues(alpha: 0.18),
                      child: SupabaseImage(
                        imagePath: transaction.imagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        fallbackIcon: Icons.receipt_long_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${DateFormat('HH:mm').format(transaction.transactionDate)} · '
                        '${transaction.categoryName.toUpperCase()} · '
                        '${transaction.walletName.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.moniaryTypography.metadata.copyWith(
                          color: colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: transaction.isIncome
                        ? colors.success
                        : colors.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionGridTile extends StatelessWidget {
  const TransactionGridTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

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
                boxShadow: transaction.isImportant
                    ? [
                        BoxShadow(
                          color: AppTheme.amber.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Hero(
                tag: 'tx_image_${transaction.id}',
                child: SupabaseImage(
                  imagePath: transaction.imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.receipt_long_outlined,
                ),
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
                      const Icon(Icons.star, color: AppTheme.amber, size: 16)
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 1000.ms,
                            curve: Curves.easeInOut,
                          )
                          .custom(
                            builder: (context, value, child) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.amber.withValues(
                                      alpha: 0.3 * value,
                                    ),
                                    blurRadius: 8 * value,
                                    spreadRadius: 2 * value,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
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
  const GridTag({super.key, required this.label});
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
