import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../core/currency/exchange_rate_repository.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/exchange_rates.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../application/stats_insights_logic.dart';
import '../../budgets/application/budget_controller.dart';
import '../../budgets/domain/monthly_budget.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../calendar/application/month/calendar_month_provider.dart';
import '../../journal/presentation/monthly_recap_screen.dart';
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

final statisticsTrendProvider =
    FutureProvider.family<List<TransactionEntry>, DateTime>((ref, month) async {
      final repo = ref.watch(transactionRepositoryProvider);
      final start = DateTime(month.year, month.month - 5, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      return repo.fetchTransactionsForRange(start: start, end: end);
    });

enum _StatsViewMode { expense, income }

class StatisticsView extends ConsumerStatefulWidget {
  const StatisticsView({super.key});

  @override
  ConsumerState<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends ConsumerState<StatisticsView> {
  late DateTime _selectedMonth;
  String? _touchedCategoryId;
  _StatsViewMode _viewMode = _StatsViewMode.expense;

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

  void _setViewMode(_StatsViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _touchedCategoryId = null;
    });
  }

  void _openMoneyStory() {
    context.push(MonthlyRecapScreen.routePath, extra: _selectedMonth);
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
    final trendAsync = ref.watch(statisticsTrendProvider(month));
    final exchangeRatesAsync = ref.watch(exchangeRatesProvider);
    final preferredCurrency = ref.watch(preferredCurrencyProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: statsAsync.when(
        data: (transactions) => _StatisticsBody(
          month: month,
          transactions: transactions,
          previousTransactions: previousStatsAsync.value,
          trendTransactions: trendAsync.value,
          budget: budgetAsync.value,
          currency: preferredCurrency,
          rates: exchangeRatesAsync.value,
          touchedCategoryId: _touchedCategoryId,
          viewMode: _viewMode,
          onChangeMonth: _changeMonth,
          onCategoryTap: _setTouchedCategory,
          onChangeViewMode: _setViewMode,
          onRefresh: () async {
            ref.invalidate(statisticsMonthProvider(month));
            ref.invalidate(statisticsMonthProvider(previousMonth));
            ref.invalidate(monthlyBudgetProvider(month));
            ref.invalidate(statisticsTrendProvider(month));
          },
          onOpenBudget: () => context.push(BudgetScreen.routePath),
          onOpenTransaction: _openTransactionDetail,
          onOpenMoneyStory: _openMoneyStory,
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
    ref.invalidate(statisticsTrendProvider(_selectedMonth));
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({
    required this.month,
    required this.transactions,
    required this.previousTransactions,
    required this.trendTransactions,
    required this.budget,
    required this.currency,
    required this.rates,
    required this.touchedCategoryId,
    required this.viewMode,
    required this.onChangeMonth,
    required this.onCategoryTap,
    required this.onChangeViewMode,
    required this.onRefresh,
    required this.onOpenBudget,
    required this.onOpenTransaction,
    required this.onOpenMoneyStory,
  });

  final DateTime month;
  final List<TransactionEntry> transactions;
  final List<TransactionEntry>? previousTransactions;
  final List<TransactionEntry>? trendTransactions;
  final MonthlyBudget? budget;
  final String currency;
  final ExchangeRates? rates;
  final String? touchedCategoryId;
  final _StatsViewMode viewMode;
  final ValueChanged<int> onChangeMonth;
  final ValueChanged<String?> onCategoryTap;
  final ValueChanged<_StatsViewMode> onChangeViewMode;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBudget;
  final ValueChanged<TransactionEntry> onOpenTransaction;
  final VoidCallback onOpenMoneyStory;

  @override
  Widget build(BuildContext context) {
    final expenseTransactions = transactions
        .where((transaction) => transaction.isExpense)
        .toList();
    final incomeTransactions = transactions
        .where((transaction) => transaction.isIncome)
        .toList();
    final expense = expenseTransactions.fold<double>(
      0,
      (sum, transaction) => sum + _amountOf(transaction, currency, rates),
    );
    final income = incomeTransactions.fold<double>(
      0,
      (sum, transaction) => sum + _amountOf(transaction, currency, rates),
    );
    final netBalance = income - expense;
    final previousExpense =
        previousTransactions
            ?.where((transaction) => transaction.isExpense)
            .fold<double>(
              0,
              (sum, transaction) =>
                  sum + _amountOf(transaction, currency, rates),
            ) ??
        0;
    final activeTransactions = viewMode == _StatsViewMode.expense
        ? expenseTransactions
        : incomeTransactions;
    final categories = _CategorySummary.fromTransactions(
      activeTransactions,
      currency,
      rates,
    );
    final selectedCategories = touchedCategoryId == null
        ? categories
        : categories
              .where((category) => category.categoryId == touchedCategoryId)
              .toList();
    final weekly = _WeeklySummary.fromTransactions(
      month,
      expenseTransactions,
      currency,
      rates,
    );
    final trend = _MonthlyTrendPoint.fromTransactions(
      month,
      trendTransactions ?? const [],
      currency,
      rates,
    );
    final largestExpenses = List<TransactionEntry>.from(expenseTransactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topCategory = categories.isEmpty ? null : categories.first;
    final insights = StatsInsightsLogic.generateInsights(
      context,
      transactions,
      previousTransactions ?? const [],
      currency,
      rates,
    );

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
                  onOpenMoneyStory: onOpenMoneyStory,
                ),
                const SizedBox(height: 28),
                _StatsHero(
                  month: month,
                  expense: expense,
                  previousExpense: previousExpense,
                  income: income,
                  netBalance: netBalance,
                  budget: budget,
                  onOpenBudget: onOpenBudget,
                ),
                if (insights.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _InsightsSection(insights: insights),
                ],
                const SizedBox(height: 25),
                if (transactions.isEmpty)
                  const _StatsEmpty()
                else ...[
                  _ViewModeToggle(mode: viewMode, onChanged: onChangeViewMode),
                  const SizedBox(height: 22),
                  if (categories.isEmpty)
                    _StatsInlineEmpty(message: context.l10n.statsEmptyTitle)
                  else
                    _CategoryDonutSection(
                      categories: categories,
                      selectedCategoryId: touchedCategoryId,
                      topCategory: topCategory,
                      onCategoryTap: onCategoryTap,
                    ),
                  if (expenseTransactions.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    _WeeklySpendingSection(weeks: weekly),
                  ],
                  if (trend.any((point) => point.amount > 0)) ...[
                    const SizedBox(height: 26),
                    _MonthlyTrendSection(points: trend),
                  ],
                  if (largestExpenses.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _LargestTransactionsSection(
                      transactions: largestExpenses.take(5).toList(),
                      onOpenTransaction: onOpenTransaction,
                    ),
                  ],
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _CategoryListSection(
                      categories: selectedCategories,
                      isFiltered: touchedCategoryId != null,
                      onShowAll: () => onCategoryTap(null),
                      onOpenTransaction: onOpenTransaction,
                    ),
                  ],
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
    required this.onOpenMoneyStory,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpenMoneyStory;

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
              icon: Icons.ios_share_outlined,
              tooltip: context.l10n.statsOpenMoneyStory,
              onTap: onOpenMoneyStory,
            ),
            const SizedBox(width: 7),
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
    required this.income,
    required this.netBalance,
    required this.budget,
    required this.onOpenBudget,
  });

  final DateTime month;
  final double expense;
  final double previousExpense;
  final double income;
  final double netBalance;
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
          amountText: _money(ref, expense),
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
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SecondaryStatPill(
              label: context.l10n.statsTotalIncome,
              amount: income,
              signed: false,
              color: colors.success,
            ),
            const SizedBox(width: 8),
            _SecondaryStatPill(
              label: context.l10n.statsNetBalance,
              amount: netBalance,
              signed: true,
              color: netBalance >= 0 ? colors.success : colors.danger,
            ),
          ],
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

class _SecondaryStatPill extends ConsumerWidget {
  const _SecondaryStatPill({
    required this.label,
    required this.amount,
    required this.color,
    this.signed = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountText = signed
        ? '${amount < 0 ? '-' : '+'}${ref.formatAmount(amount.abs())}'
        : _money(ref, amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: context.moniaryTypography.metadata.copyWith(
              color: color,
              fontSize: 7.5,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          ObscurableAmountText(
            amountText: amountText,
            style: TextStyle(
              color: color,
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights});

  final List<StatsInsight> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: context.l10n.statsInsightTitle),
        const SizedBox(height: 12),
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _InsightCard(insight: insights[i]),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final StatsInsight insight;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = switch (insight.type) {
      InsightType.success => colors.success,
      InsightType.warning => AppTheme.terracotta,
      InsightType.info => colors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final _StatsViewMode mode;
  final ValueChanged<_StatsViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _controlFill(colors),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _controlBorder(colors)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewModeSegment(
              label: context.l10n.statsExpenseButton,
              selected: mode == _StatsViewMode.expense,
              onTap: () => onChanged(_StatsViewMode.expense),
            ),
          ),
          Expanded(
            child: _ViewModeSegment(
              label: context.l10n.statsIncomeButton,
              selected: mode == _StatsViewMode.income,
              onTap: () => onChanged(_StatsViewMode.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeSegment extends StatelessWidget {
  const _ViewModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: selected ? AppTheme.terracotta : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? colors.backgroundSoft : colors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsInlineEmpty extends StatelessWidget {
  const _StatsInlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.textDim),
      ),
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
                    _categoryLabel(
                      context,
                      active?.categoryName ?? '',
                    ).toUpperCase(),
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
                label: _categoryLabel(context, item.categoryName),
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

class _MonthlyTrendSection extends StatelessWidget {
  const _MonthlyTrendSection({required this.points});

  final List<_MonthlyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<double>(
      0,
      (max, point) => point.amount > max ? point.amount : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: context.l10n.statsMonthlyTrend),
        const SizedBox(height: 18),
        SizedBox(
          height: 112,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              final ratio = maxAmount <= 0 ? 0.0 : point.amount / maxAmount;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == points.length - 1 ? 0 : 10,
                  ),
                  child: _TrendBar(point: point, ratio: ratio),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.point, required this.ratio});

  final _MonthlyTrendPoint point;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final locale = Localizations.localeOf(context).toString();
    final color = point.isCurrent
        ? AppTheme.terracotta
        : Color.lerp(AppTheme.taupe, colors.backgroundSoft, 0.2)!;
    final height = 23 + (ratio * 52);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _compactAmount(context, point.amount),
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: point.isCurrent ? AppTheme.terracotta : colors.textDim,
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
          DateFormat.MMM(locale).format(point.month).toUpperCase(),
          maxLines: 1,
          style: context.moniaryTypography.metadata.copyWith(
            color: point.isCurrent ? AppTheme.terracotta : colors.textDim,
            fontSize: 8,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _LargestTransactionsSection extends StatelessWidget {
  const _LargestTransactionsSection({
    required this.transactions,
    required this.onOpenTransaction,
  });

  final List<TransactionEntry> transactions;
  final ValueChanged<TransactionEntry> onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: context.l10n.statsLargestTransactions),
        const SizedBox(height: 12),
        ...transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          return _LargestTransactionRow(
            transaction: transaction,
            color: _statColor(index, transaction.categoryColor),
            onTap: () => onOpenTransaction(transaction),
          );
        }),
      ],
    );
  }
}

class _LargestTransactionRow extends ConsumerWidget {
  const _LargestTransactionRow({
    required this.transaction,
    required this.color,
    required this.onTap,
  });

  final TransactionEntry transaction;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final locale = Localizations.localeOf(context).toString();
    final note = transaction.note?.trim() ?? '';
    final title = note.isNotEmpty
        ? note
        : _categoryLabel(context, transaction.categoryName);
    final subtitle =
        '${_categoryLabel(context, transaction.categoryName)} · '
        '${DateFormat.MMMd(locale).format(transaction.transactionDate)}';

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
                          title,
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
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    amountText: _money(ref, transaction.amount),
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
                          _categoryLabel(context, category.categoryName),
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
                    amountText: _money(ref, category.amount),
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
    String currency,
    ExchangeRates? rates,
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
          (sum, transaction) => sum + _amountOf(transaction, currency, rates),
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
    String currency,
    ExchangeRates? rates,
  ) {
    final buckets = List<double>.filled(4, 0);
    for (final transaction in transactions) {
      if (transaction.transactionDate.year != month.year ||
          transaction.transactionDate.month != month.month) {
        continue;
      }
      final index = ((transaction.transactionDate.day - 1) ~/ 7).clamp(0, 3);
      buckets[index] += _amountOf(transaction, currency, rates);
    }
    return List.generate(
      4,
      (index) => _WeeklySummary(index: index + 1, amount: buckets[index]),
    );
  }
}

class _MonthlyTrendPoint {
  const _MonthlyTrendPoint({
    required this.month,
    required this.amount,
    required this.isCurrent,
  });

  final DateTime month;
  final double amount;
  final bool isCurrent;

  static List<_MonthlyTrendPoint> fromTransactions(
    DateTime month,
    List<TransactionEntry> transactions,
    String currency,
    ExchangeRates? rates,
  ) {
    return List.generate(6, (index) {
      final offset = 5 - index;
      final bucketMonth = DateTime(month.year, month.month - offset);
      final amount = transactions
          .where(
            (transaction) =>
                transaction.isExpense &&
                transaction.transactionDate.year == bucketMonth.year &&
                transaction.transactionDate.month == bucketMonth.month,
          )
          .fold<double>(
            0,
            (sum, transaction) => sum + _amountOf(transaction, currency, rates),
          );
      return _MonthlyTrendPoint(
        month: bucketMonth,
        amount: amount,
        isCurrent: offset == 0,
      );
    });
  }
}

String _categoryLabel(BuildContext context, String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? context.l10n.categoryOther : trimmed;
}

String _money(WidgetRef ref, double amount) {
  return ref.formatAmount(amount);
}

/// Converts to [currency] using [rates] when available, falling back to the
/// raw amount (e.g. rates still loading) rather than dropping data.
double _amountOf(TransactionEntry t, String currency, ExchangeRates? rates) {
  return rates == null ? t.amount : t.amountIn(currency, rates);
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
