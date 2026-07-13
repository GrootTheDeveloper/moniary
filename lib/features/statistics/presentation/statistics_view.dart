import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../../budgets/application/budget_controller.dart';
import '../../budgets/domain/monthly_budget.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../calendar/application/month/calendar_month_provider.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../transactions/domain/models/transaction_mutation_result.dart';
import '../../transactions/presentation/detail/transaction_detail_screen.dart';
import '../../transactions/presentation/detail/transaction_route_args.dart';

final statisticsMonthProvider =
    FutureProvider.family<List<TransactionEntry>, DateTime>((ref, month) async {
      final repo = ref.watch(transactionRepositoryProvider);
      return repo.fetchTransactionsForMonth(month);
    });

class StatisticsView extends ConsumerStatefulWidget {
  const StatisticsView({super.key});

  @override
  ConsumerState<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends ConsumerState<StatisticsView> {
  late DateTime _selectedMonth;
  String? _touchedCategoryId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
      _touchedCategoryId = null;
    });
  }

  void _setTouchedCategory(String? categoryId) {
    setState(() {
      if (categoryId == null || _touchedCategoryId == categoryId) {
        _touchedCategoryId = null;
      } else {
        _touchedCategoryId = categoryId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final month = DateTime(_selectedMonth.year, _selectedMonth.month);
    final previousMonth = DateTime(month.year, month.month - 1);
    final statsAsync = ref.watch(statisticsMonthProvider(month));
    final previousStatsAsync = ref.watch(
      statisticsMonthProvider(previousMonth),
    );
    final budgetAsync = ref.watch(monthlyBudgetProvider(month));
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: statsAsync.when(
        data: (transactions) => _StatisticsBody(
          month: month,
          transactions: transactions,
          previousTransactions: previousStatsAsync.value,
          budget: budgetAsync.value,
          touchedCategoryId: _touchedCategoryId,
          onChangeMonth: _changeMonth,
          onCategoryTap: _setTouchedCategory,
          onRefresh: () async {
            ref.invalidate(statisticsMonthProvider(month));
            ref.invalidate(statisticsMonthProvider(previousMonth));
            ref.invalidate(monthlyBudgetProvider(month));
          },
          onOpenBudget: () => context.push(BudgetScreen.routePath),
          onOpenTransaction: _openTransactionDetail,
        ),
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load statistics', error, stackTrace);
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  userFriendlyMessage(context, error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openTransactionDetail(TransactionEntry transaction) async {
    final result = await context.push<TransactionMutationResult>(
      TransactionDetailScreen.routePath,
      extra: TransactionDetailRouteArgs(
        transaction: transaction,
        day: transaction.transactionDate,
      ),
    );
    if (result != null && mounted) {
      _invalidateMutationMonths(result);
    }
  }

  void _invalidateMutationMonths(TransactionMutationResult result) {
    final months = <DateTime>{
      if (result.previousDate != null)
        DateTime(result.previousDate!.year, result.previousDate!.month),
      if (result.currentDate != null)
        DateTime(result.currentDate!.year, result.currentDate!.month),
    };

    for (final month in months) {
      ref.invalidate(statisticsMonthProvider(month));
      ref.invalidate(calendarMonthProvider(month));
      ref.invalidate(monthlyBudgetProvider(month));
    }
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({
    required this.month,
    required this.transactions,
    required this.previousTransactions,
    required this.budget,
    required this.touchedCategoryId,
    required this.onChangeMonth,
    required this.onCategoryTap,
    required this.onRefresh,
    required this.onOpenBudget,
    required this.onOpenTransaction,
  });

  final DateTime month;
  final List<TransactionEntry> transactions;
  final List<TransactionEntry>? previousTransactions;
  final MonthlyBudget? budget;
  final String? touchedCategoryId;
  final ValueChanged<int> onChangeMonth;
  final ValueChanged<String?> onCategoryTap;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBudget;
  final ValueChanged<TransactionEntry> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final expenseTransactions = transactions
        .where((transaction) => transaction.isExpense)
        .toList();
    final expense = expenseTransactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    final previousExpense =
        previousTransactions
            ?.where((transaction) => transaction.isExpense)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount) ??
        0;
    final categories = _CategorySummary.fromTransactions(expenseTransactions);
    final selectedCategories = touchedCategoryId == null
        ? categories
        : categories
              .where((category) => category.categoryId == touchedCategoryId)
              .toList();
    final weekly = _WeeklySummary.fromTransactions(month, expenseTransactions);
    final topCategory = categories.isEmpty ? null : categories.first;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: RefreshIndicator(
            color: context.moniaryColors.primary,
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 116),
              children: [
                _StatsHeader(
                  month: month,
                  onPrevious: () => onChangeMonth(-1),
                  onNext: () => onChangeMonth(1),
                ),
                const SizedBox(height: 28),
                _StatsHero(
                  month: month,
                  expense: expense,
                  previousExpense: previousExpense,
                  budget: budget,
                  onOpenBudget: onOpenBudget,
                ),
                const SizedBox(height: 25),
                if (categories.isEmpty)
                  const _StatsEmpty()
                else ...[
                  _CategoryDonutSection(
                    categories: categories,
                    selectedCategoryId: touchedCategoryId,
                    topCategory: topCategory,
                    onCategoryTap: onCategoryTap,
                  ),
                  const SizedBox(height: 25),
                  _WeeklySpendingSection(weeks: weekly),
                  const SizedBox(height: 26),
                  _CategoryListSection(
                    categories: selectedCategories,
                    isFiltered: touchedCategoryId != null,
                    onShowAll: () => onCategoryTap(null),
                    onOpenTransaction: onOpenTransaction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.appName.toUpperCase(),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: AppTheme.terracotta,
                  fontSize: 8.5,
                  letterSpacing: 2.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.navStatsLabel,
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _HeaderArrowButton(
              icon: Icons.arrow_back_ios_new_rounded,
              tooltip: MaterialLocalizations.of(context).previousPageTooltip,
              onTap: onPrevious,
            ),
            const SizedBox(width: 7),
            _HeaderArrowButton(
              icon: Icons.arrow_forward_ios_rounded,
              tooltip: MaterialLocalizations.of(context).nextPageTooltip,
              onTap: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderArrowButton extends StatelessWidget {
  const _HeaderArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _controlFill(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _controlBorder(colors), width: 1.15),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 15, color: colors.textDim),
          ),
        ),
      ),
    );
  }
}

class _StatsHero extends ConsumerWidget {
  const _StatsHero({
    required this.month,
    required this.expense,
    required this.previousExpense,
    required this.budget,
    required this.onOpenBudget,
  });

  final DateTime month;
  final double expense;
  final double previousExpense;
  final MonthlyBudget? budget;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final monthLabel = _monthLabel(context, month);
    final budgetProgress = budget?.progress ?? 0;
    final hasBudget = (budget?.totalLimit ?? 0) > 0;

    return Column(
      children: [
        Text(
          context.l10n.statsMonthExpenseMeta(monthLabel).toUpperCase(),
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: colors.textDim,
            fontSize: 9,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 7),
        ObscurableAmountText(
          amountText: _money(context, ref, expense),
          style: context.moniaryTypography.displayLarge.copyWith(
            color: colors.textPrimary,
            fontSize: 43,
            height: 1,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _expenseDeltaText(context, expense, previousExpense),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: expense <= previousExpense && previousExpense > 0
                ? colors.success
                : colors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 17),
        Material(
          color: AppTheme.terracotta.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: AppTheme.terracotta.withValues(alpha: 0.34),
              width: 1.1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onOpenBudget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppTheme.terracotta,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    hasBudget
                        ? context.l10n.statsBudgetUsed(
                            (budgetProgress * 100).round(),
                          )
                        : context.l10n.statsBudgetNoLimit,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.terracotta,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.terracotta,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDonutSection extends StatelessWidget {
  const _CategoryDonutSection({
    required this.categories,
    required this.selectedCategoryId,
    required this.topCategory,
    required this.onCategoryTap,
  });

  final List<_CategorySummary> categories;
  final String? selectedCategoryId;
  final _CategorySummary? topCategory;
  final ValueChanged<String?> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (sum, item) => sum + item.amount);
    final active =
        categories
            .where((item) => item.categoryId == selectedCategoryId)
            .firstOrNull ??
        topCategory;
    final activePercent = total <= 0 || active == null
        ? 0
        : ((active.amount / total) * 100).round();
    final sections = categories.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final selected = selectedCategoryId == item.categoryId;
      return PieChartSectionData(
        value: item.amount,
        showTitle: false,
        radius: selected ? 38 : 34,
        color: _statColor(index, item.categoryColor),
      );
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 43,
                  sectionsSpace: 0,
                  startDegreeOffset: -90,
                  sections: sections,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent || response == null) return;
                      final index =
                          response.touchedSection?.touchedSectionIndex;
                      if (index == null ||
                          index < 0 ||
                          index >= categories.length) {
                        return;
                      }
                      onCategoryTap(categories[index].categoryId);
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$activePercent%',
                    style: context.moniaryTypography.displaySmall.copyWith(
                      fontSize: 20,
                      color: context.moniaryColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (active?.categoryName ?? '').toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: context.moniaryColors.textDim,
                      fontSize: 7.5,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final percent = total <= 0
                  ? 0
                  : ((item.amount / total) * 100).round();
              final selected = selectedCategoryId == item.categoryId;
              return _LegendRow(
                color: _statColor(index, item.categoryColor),
                label: item.categoryName,
                percent: percent,
                selected: selected,
                onTap: () => onCategoryTap(item.categoryId),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final int percent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: selected ? Border.all(color: colors.textPrimary) : null,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySpendingSection extends StatelessWidget {
  const _WeeklySpendingSection({required this.weeks});

  final List<_WeeklySummary> weeks;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final maxAmount = weeks.fold<double>(
      0,
      (max, week) => week.amount > max ? week.amount : max,
    );
    final activeIndex = weeks.indexWhere((week) => week.amount == maxAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: context.l10n.statsWeeklySpending),
        const SizedBox(height: 18),
        SizedBox(
          height: 112,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeks.asMap().entries.map((entry) {
              final index = entry.key;
              final week = entry.value;
              final ratio = maxAmount <= 0 ? 0.0 : week.amount / maxAmount;
              final selected = index == activeIndex && week.amount > 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == weeks.length - 1 ? 0 : 10,
                  ),
                  child: _WeekBar(
                    week: week,
                    ratio: ratio,
                    selected: selected,
                    color: selected
                        ? AppTheme.terracotta
                        : Color.lerp(
                            AppTheme.taupe,
                            colors.backgroundSoft,
                            0.2,
                          )!,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.week,
    required this.ratio,
    required this.selected,
    required this.color,
  });

  final _WeeklySummary week;
  final double ratio;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final height = 23 + (ratio * 52);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _compactAmount(context, week.amount),
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: selected
                ? AppTheme.terracotta
                : context.moniaryColors.textDim,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.statsWeekLabel(week.index).toUpperCase(),
          maxLines: 1,
          style: context.moniaryTypography.metadata.copyWith(
            color: selected
                ? AppTheme.terracotta
                : context.moniaryColors.textDim,
            fontSize: 8,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _CategoryListSection extends StatelessWidget {
  const _CategoryListSection({
    required this.categories,
    required this.isFiltered,
    required this.onShowAll,
    required this.onOpenTransaction,
  });

  final List<_CategorySummary> categories;
  final bool isFiltered;
  final VoidCallback onShowAll;
  final ValueChanged<TransactionEntry> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _SectionLabel(label: context.l10n.statsCategories)),
            if (isFiltered)
              TextButton(
                onPressed: onShowAll,
                child: Text(context.l10n.commonViewAll),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          return _CategoryAmountRow(
            category: category,
            color: _statColor(index, category.categoryColor),
            onTap: category.transactions.isEmpty
                ? null
                : () => onOpenTransaction(category.transactions.first),
          );
        }),
      ],
    );
  }
}

class _CategoryAmountRow extends ConsumerWidget {
  const _CategoryAmountRow({
    required this.category,
    required this.color,
    required this.onTap,
  });

  final _CategorySummary category;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.transactionCount(
                            category.transactions.length,
                          ),
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ObscurableAmountText(
                    amountText: _money(context, ref, category.amount),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: colors.outline.withValues(alpha: 0.72)),
      ],
    );
  }
}

class _StatsEmpty extends StatelessWidget {
  const _StatsEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 34, color: colors.textDim),
          const SizedBox(height: 12),
          Text(
            context.l10n.statsEmptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.statsEmptySubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textDim,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.moniaryTypography.metadataStrong.copyWith(
        color: context.moniaryColors.textDim,
        fontSize: 9,
        letterSpacing: 2.4,
      ),
    );
  }
}

class _CategorySummary {
  const _CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.transactions,
    this.categoryColor,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final double amount;
  final List<TransactionEntry> transactions;

  static List<_CategorySummary> fromTransactions(
    List<TransactionEntry> transactions,
  ) {
    final grouped = <String, List<TransactionEntry>>{};
    for (final transaction in transactions) {
      grouped.putIfAbsent(transaction.categoryId, () => []).add(transaction);
    }

    final summaries = grouped.entries.map((entry) {
      final items = entry.value;
      final first = items.first;
      return _CategorySummary(
        categoryId: first.categoryId,
        categoryName: first.categoryName,
        categoryColor: first.categoryColor,
        amount: items.fold<double>(
          0,
          (sum, transaction) => sum + transaction.amount,
        ),
        transactions: List<TransactionEntry>.from(items)
          ..sort((a, b) => b.amount.compareTo(a.amount)),
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return summaries.take(6).toList();
  }
}

class _WeeklySummary {
  const _WeeklySummary({required this.index, required this.amount});

  final int index;
  final double amount;

  static List<_WeeklySummary> fromTransactions(
    DateTime month,
    List<TransactionEntry> transactions,
  ) {
    final buckets = List<double>.filled(4, 0);
    for (final transaction in transactions) {
      if (transaction.transactionDate.year != month.year ||
          transaction.transactionDate.month != month.month) {
        continue;
      }
      final index = ((transaction.transactionDate.day - 1) ~/ 7).clamp(0, 3);
      buckets[index] += transaction.amount;
    }
    return List.generate(
      4,
      (index) => _WeeklySummary(index: index + 1, amount: buckets[index]),
    );
  }
}

String _money(BuildContext context, WidgetRef ref, double amount) {
  final formatter = NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    symbol: '',
    decimalDigits: 0,
  );
  return '${formatter.format(amount).trim()}${ref.currencySymbol}';
}

String _compactAmount(BuildContext context, double amount) {
  if (amount <= 0) return '0';
  final millions = amount / 1000000;
  if (millions >= 0.1) {
    final value = NumberFormat.decimalPatternDigits(
      locale: Localizations.localeOf(context).toString(),
      decimalDigits: 1,
    ).format(millions);
    return '$value${context.l10n.statsMillionShort}';
  }
  final thousands = (amount / 1000).round();
  return '${thousands}k';
}

String _expenseDeltaText(
  BuildContext context,
  double expense,
  double previousExpense,
) {
  if (previousExpense <= 0) return context.l10n.statsExpenseNoPrevious;
  final deltaPercent =
      (((expense - previousExpense).abs() / previousExpense) * 100).round();
  if (deltaPercent == 0) return context.l10n.statsExpenseSameAsPrevious;
  if (expense < previousExpense) {
    return context.l10n.statsExpenseLessThanPrevious(deltaPercent);
  }
  return context.l10n.statsExpenseMoreThanPrevious(deltaPercent);
}

String _monthLabel(BuildContext context, DateTime month) {
  final locale = Localizations.localeOf(context).toString();
  final label = DateFormat.MMMM(locale).format(month);
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

Color _statColor(int index, String? rawColor) {
  const palette = [
    Color(0xFFA98C86),
    Color(0xFFC2A98E),
    Color(0xFF7E8CA0),
    Color(0xFF8E9B8F),
    Color(0xFFB8B0A5),
    Color(0xFF9A8AA5),
  ];
  if (rawColor == null || rawColor.isEmpty) {
    return palette[index % palette.length];
  }
  final parsed = AppColor.fromHex(
    rawColor,
    fallback: palette[index % palette.length],
  );
  return Color.lerp(parsed, palette[index % palette.length], 0.64)!;
}

Color _controlFill(MoniaryColors colors) {
  return Color.lerp(colors.backgroundSoft, colors.textPrimary, 0.025)!;
}

Color _controlBorder(MoniaryColors colors) {
  return Color.lerp(colors.outline, colors.textPrimary, 0.08)!;
}
