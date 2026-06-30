import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../categories/domain/models/category.dart';
import '../../calendar/application/month/calendar_month_provider.dart';
import '../../transactions/data/repositories/transaction_repository.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../transactions/domain/models/transaction_mutation_result.dart';
import '../../transactions/presentation/detail/transaction_detail_screen.dart';
import '../../transactions/presentation/detail/transaction_route_args.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../shared/utils/currency_formatter.dart';

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
  TransactionType _selectedType = TransactionType.expense;
  String? _touchedCategoryId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
        1,
      );
      _touchedCategoryId = null;
    });
  }

  void _setSelectedType(TransactionType type) {
    setState(() {
      _selectedType = type;
      _touchedCategoryId = null;
    });
  }

  void _setTouchedCategory(String? categoryId) {
    setState(() {
      if (categoryId == null) {
        _touchedCategoryId = null;
        return;
      }

      _touchedCategoryId = _touchedCategoryId == categoryId ? null : categoryId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(statisticsMonthProvider(_selectedMonth));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.statsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: statsAsync.when(
        data: (transactions) => _buildBody(context, transactions),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.mint),
        ),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load statistics', error, stackTrace);
          return Center(child: Text(userFriendlyMessage(context, error)));
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<TransactionEntry> transactions) {
    final income = transactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final net = income - expense;

    // Filter transactions by type for chart calculations
    final filteredByType = transactions
        .where((t) => t.type == _selectedType)
        .toList();

    final filteredBySelection = _touchedCategoryId == null
        ? filteredByType
        : filteredByType
              .where((t) => t.categoryId == _touchedCategoryId)
              .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(statisticsMonthProvider(_selectedMonth));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildMonthSelector(context),
          const SizedBox(height: 16),
          _buildSummaryCards(income, expense, net),
          const SizedBox(height: 16),
          _buildImportantSpendingCard(transactions),
          const SizedBox(height: 24),
          _buildTypeToggle(),
          const SizedBox(height: 20),
          if (filteredByType.isEmpty)
            _buildEmptyState()
          else ...[
            _buildPieChartSection(filteredByType),
            const SizedBox(height: 24),
            _buildTrendChartSection(filteredByType),
            const SizedBox(height: 24),
            _buildTopSpendingList(filteredBySelection),
          ],
          const SizedBox(height: 100), // Spacing for floating action button
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final label = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    ).format(_selectedMonth);
    final title =
        '${label[0].toUpperCase()}${label.substring(1)} ${_selectedMonth.year}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double net) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: context.l10n.statsTotalIncome,
                value: _money(context, income),
                color: AppTheme.success,
                icon: Icons.north_east_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: context.l10n.statsTotalExpense,
                value: _money(context, expense),
                color: AppTheme.danger,
                icon: Icons.south_east_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.statsNetBalance,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ObscurableAmountText(
                prefixText: net >= 0 ? '+' : '-',
                amountText: _money(context, net.abs()),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportantSpendingCard(List<TransactionEntry> transactions) {
    final importantTransactions = transactions
        .where((t) => t.isImportant)
        .toList();
    if (importantTransactions.isEmpty) return const SizedBox.shrink();

    final importantIncome = importantTransactions
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final importantExpense = importantTransactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.amber.withValues(alpha: 0.1), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppTheme.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.starredTransactionsTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.calendarIncome,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ObscurableAmountText(
                      amountText: _money(context, importantIncome),
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white10),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.calendarExpense,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ObscurableAmountText(
                      amountText: _money(context, importantExpense),
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: context.l10n.statsExpenseButton,
              selected: _selectedType == TransactionType.expense,
              onTap: () => _setSelectedType(TransactionType.expense),
              color: AppTheme.danger,
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: context.l10n.statsIncomeButton,
              selected: _selectedType == TransactionType.income,
              onTap: () => _setSelectedType(TransactionType.income),
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          const Icon(Icons.bar_chart_outlined, size: 64, color: Colors.white54),
          const SizedBox(height: 12),
          Text(
            context.l10n.statsEmptyTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.statsEmptySubtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(List<TransactionEntry> transactions) {
    // 1. Group sums
    final categorySums = <String, double>{};
    final categoryNames = <String, String>{};
    final categoryColors = <String, String>{};

    for (final tx in transactions) {
      categorySums[tx.categoryId] =
          (categorySums[tx.categoryId] ?? 0) + tx.amount;
      categoryNames[tx.categoryId] = tx.categoryName.trim().isEmpty
          ? context.l10n.categoryOther
          : tx.categoryName;
      categoryColors[tx.categoryId] = tx.categoryColor ?? '';
    }

    final total = categorySums.values.fold<double>(0, (sum, val) => sum + val);

    final pieSections = categorySums.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
      final color = AppColor.fromHex(
        categoryColors[entry.key],
        fallback: AppTheme.amber,
      );
      final isTouched = _touchedCategoryId == entry.key;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 42 : 36,
        showTitle: percentage >= 5,
        titleStyle: TextStyle(
          fontSize: isTouched ? 12 : 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        color: color,
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 10, color: color),
              )
            : null,
        badgePositionPercentageOffset: 1.1,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.statsCategoryAllocation,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_touchedCategoryId != null)
                TextButton(
                  onPressed: () => _setTouchedCategory(null),
                  child: Text(
                    context.l10n.commonViewAll,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: pieSections,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response != null) {
                          final index =
                              response.touchedSection?.touchedSectionIndex;
                          if (index != null && index >= 0) {
                            _setTouchedCategory(
                              categorySums.keys.elementAt(index),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: categorySums.entries.map((entry) {
                    final percentage = total > 0
                        ? (entry.value / total) * 100
                        : 0.0;
                    final color = AppColor.fromHex(
                      categoryColors[entry.key],
                      fallback: AppTheme.amber,
                    );
                    final isTouched = _touchedCategoryId == entry.key;

                    return GestureDetector(
                      onTap: () => _setTouchedCategory(entry.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isTouched
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categoryNames[entry.key]!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isTouched
                                      ? Colors.white
                                      : Colors.white54,
                                  fontWeight: isTouched
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: isTouched
                                    ? Colors.white
                                    : Colors.white24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartSection(List<TransactionEntry> transactions) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final dailySums = List<double>.filled(daysInMonth, 0.0);

    for (final tx in transactions) {
      if (tx.transactionDate.month == _selectedMonth.month &&
          tx.transactionDate.year == _selectedMonth.year) {
        final dayIndex = tx.transactionDate.day - 1;
        if (dayIndex >= 0 && dayIndex < daysInMonth) {
          dailySums[dayIndex] += tx.amount;
        }
      }
    }

    final maxVal = dailySums.isEmpty
        ? 0.0
        : dailySums.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal > 0 ? maxVal * 1.15 : 10000.0;

    final barGroups = List<BarChartGroupData>.generate(daysInMonth, (index) {
      final dayVal = dailySums[index];
      return BarChartGroupData(
        x: index + 1,
        barRods: [
          BarChartRodData(
            toY: dayVal,
            color: _selectedType == TransactionType.expense
                ? AppTheme.danger
                : AppTheme.mint,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statsDailyTrend,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: daysInMonth * 26.0 + 32,
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.surfaceRaised,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          context.l10n.statsDayTooltip(
                            group.x.toInt(),
                            _money(context, rod.toY),
                          ),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt();
                          if (day % 5 == 0 || day == 1 || day == daysInMonth) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '$day',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpendingList(List<TransactionEntry> transactions) {
    // Sort descending by amount
    final sortedTxs = List<TransactionEntry>.from(transactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Take top 5 unless filtered
    final isFiltered = _touchedCategoryId != null;
    final displayTxs = isFiltered ? sortedTxs : sortedTxs.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFiltered
                    ? context.l10n.statsCategoryTransactions
                    : context.l10n.statsLargestTransactions,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (!isFiltered && sortedTxs.length > 5)
                const Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: Colors.white24,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTxs.length,
            itemBuilder: (context, index) {
              final tx = displayTxs[index];
              final accent = AppColor.fromHex(
                tx.categoryColor ?? tx.walletColor,
                fallback: AppTheme.amber,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () async {
                    final result = await context
                        .push<TransactionMutationResult>(
                          TransactionDetailScreen.routePath,
                          extra: TransactionDetailRouteArgs(
                            transaction: tx,
                            day: tx.transactionDate,
                          ),
                        );
                    if (result != null && mounted) {
                      _invalidateMutationMonths(result);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: accent,
                            size: 20,
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
                                      tx.note?.trim().isNotEmpty == true
                                          ? tx.note!.trim()
                                          : tx.categoryName.trim().isEmpty
                                          ? context.l10n.categoryOther
                                          : tx.categoryName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (tx.isImportant) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.amber,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${MaterialLocalizations.of(context).formatShortDate(tx.transactionDate)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(tx.transactionDate), alwaysUse24HourFormat: true)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ObscurableAmountText(
                          amountText: _money(context, tx.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tx.isIncome
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _money(BuildContext context, double amount) {
    return formatCurrency(
      amount,
      currencyCode: ref.watch(preferredCurrencyProvider),
      locale: Localizations.localeOf(context).toString(),
    );
  }

  void _invalidateMutationMonths(TransactionMutationResult result) {
    final months = <DateTime>{
      if (result.previousDate != null)
        DateTime(result.previousDate!.year, result.previousDate!.month, 1),
      if (result.currentDate != null)
        DateTime(result.currentDate!.year, result.currentDate!.month, 1),
    };

    for (final month in months) {
      ref.invalidate(statisticsMonthProvider(month));
      ref.invalidate(calendarMonthProvider(month));
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ObscurableAmountText(
                    amountText: value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppTheme.textSubtle,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
