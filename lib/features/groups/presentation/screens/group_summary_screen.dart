import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/spending_group.dart';

class GroupSummaryScreen extends ConsumerStatefulWidget {
  const GroupSummaryScreen({required this.groupId, super.key});

  static const routePath = '/group-summary';
  final String groupId;

  @override
  ConsumerState<GroupSummaryScreen> createState() => _GroupSummaryScreenState();
}

class _GroupSummaryScreenState extends ConsumerState<GroupSummaryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final key = (groupId: widget.groupId, month: _month);
    final statsAsync = ref.watch(groupMonthlyStatsProvider(key));
    final trendAsync = ref.watch(groupMonthlyTrendProvider(widget.groupId));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final budgetAsync = ref.watch(groupBudgetProvider(widget.groupId));
    final historyAsync = ref.watch(
      groupSettlementHistoryProvider(widget.groupId),
    );
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupSummaryTitle)),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _SummaryMessage(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupMonthlyStatsProvider(key)),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupMonthlyStatsProvider(key));
            ref.invalidate(groupSettlementHistoryProvider(widget.groupId));
            ref.invalidate(groupDetailProvider(widget.groupId));
            ref.invalidate(groupBudgetProvider(widget.groupId));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              if (detailAsync.asData != null)
                _SummaryGroupHeader(
                  detail: detailAsync.asData!.value,
                  stats: stats,
                  formattedTotal: ref.formatAmount(stats.totalSpent),
                  formattedBalance: ref.formatAmount(
                    detailAsync.asData!.value.group.currentUserBalance.abs(),
                  ),
                  balanceLabel:
                      detailAsync.asData!.value.group.currentUserBalance == 0
                      ? context.l10n.groupBalanceSettled
                      : detailAsync.asData!.value.group.currentUserBalance > 0
                      ? context.l10n.groupDetailYouPay
                      : context.l10n.groupDetailReceiveBack,
                )
              else
                Text(context.l10n.groupSummarySubtitle),
              const SizedBox(height: 16),
              _MonthSelector(
                month: _month,
                onPrevious: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                onNext: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
              const SizedBox(height: 16),
              _BudgetProgressCard(
                budgetAsync: budgetAsync,
                spent: stats.totalSpent,
                formatAmount: ref.formatAmount,
              ),
              const SizedBox(height: 12),
              MoniaryEditorialCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: context.l10n.groupSummaryTotalSpent,
                        value: ref.formatAmount(stats.totalSpent),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: context.moniaryColors.outline,
                    ),
                    Expanded(
                      child: _Metric(
                        label: context.l10n.groupSummaryTransactions,
                        value: '${stats.transactionCount}',
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.transactionCount > 0 &&
                  stats.memberBreakdown.every((member) => member.balance == 0))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: context.moniaryColors.success.withValues(
                      alpha: 0.12,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.verified_outlined,
                        color: context.moniaryColors.success,
                      ),
                      title: Text(context.l10n.groupSettlementBadgeTitle),
                      subtitle: Text(context.l10n.groupSettlementBadgeSubtitle),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (stats.memberBreakdown.isNotEmpty) ...[
                _ContributionSpotlight(stats: stats),
                const SizedBox(height: 18),
              ],
              _SummaryCharts(stats: stats, trendAsync: trendAsync),
              const SizedBox(height: 18),
              _SummaryCollapsibleSection(
                title: context.l10n.groupSummaryCategories,
                count: stats.categoryBreakdown.length,
                initiallyExpanded: true,
                child: stats.categoryBreakdown.isEmpty
                    ? _EmptyCard(text: context.l10n.groupSummaryNoData)
                    : Column(
                        children: [
                          for (final category in stats.categoryBreakdown)
                            ListTile(
                              title: Text(category.categoryName),
                              subtitle: Text(
                                context.l10n.groupSummaryTransactionCount(
                                  category.transactionCount,
                                ),
                              ),
                              trailing: Text(
                                ref.formatAmount(category.totalAmount),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              _SummaryCollapsibleSection(
                title: context.l10n.groupSummaryMembers,
                count: stats.memberBreakdown.length,
                child: stats.memberBreakdown.isEmpty
                    ? _EmptyCard(text: context.l10n.groupSummaryNoData)
                    : Column(
                        children: [
                          for (final member in stats.memberBreakdown)
                            ListTile(
                              title: Text(member.displayName),
                              subtitle: Text(
                                context.l10n.groupSummaryMemberAmounts(
                                  ref.formatAmount(member.shareAmount),
                                  ref.formatAmount(member.paidAmount),
                                ),
                              ),
                              trailing: Text(
                                ref.formatAmount(member.balance),
                                style: TextStyle(
                                  color: member.balance == 0
                                      ? context.moniaryColors.textDim
                                      : member.balance > 0
                                      ? context.moniaryColors.danger
                                      : context.moniaryColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              _SummaryCollapsibleSection(
                title: context.l10n.groupSummarySettlementHistory,
                child: historyAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) =>
                      _EmptyCard(text: userFriendlyMessage(context, error)),
                  data: (history) => history.isEmpty
                      ? _EmptyCard(text: context.l10n.groupSummaryNoHistory)
                      : Column(
                          children: [
                            for (final entry in history)
                              ListTile(
                                title: Text(
                                  context.l10n.groupSummarySettlementPair(
                                    entry.fromName,
                                    entry.toName,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_statusLabel(context, entry.status)} · '
                                  '${DateFormat('dd/MM/yyyy').format(entry.updatedAt.toLocal())}',
                                ),
                                trailing: Text(ref.formatAmount(entry.amount)),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) => switch (status) {
    'completed' => context.l10n.groupSettlementCompleted,
    'disputed' => context.l10n.groupSettlementDisputed,
    'payer_marked_paid' => context.l10n.groupSettlementPayerMarked,
    _ => context.l10n.groupSettlementPending,
  };
}

class _SummaryGroupHeader extends StatelessWidget {
  const _SummaryGroupHeader({
    required this.detail,
    required this.stats,
    required this.formattedTotal,
    required this.formattedBalance,
    required this.balanceLabel,
  });

  final SpendingGroupDetail detail;
  final GroupMonthlyStats stats;
  final String formattedTotal;
  final String formattedBalance;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SupabaseImage(
                imagePath: detail.group.avatarPath,
                width: 62,
                height: 62,
                borderRadius: BorderRadius.circular(18),
                fallbackBuilder: (_) => const _SummaryAvatarFallback(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.displaySmall.copyWith(
                        fontSize: 25,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.l10n.groupMemberCount(
                        detail.activeMembers.length,
                      ),
                      style: context.moniaryTypography.metadata.copyWith(
                        color: colors.textDim,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 24,
                      child: Stack(
                        children: [
                          for (
                            var index = 0;
                            index < detail.activeMembers.take(5).length;
                            index++
                          )
                            Positioned(
                              left: index * 18,
                              child: SupabaseImage(
                                imagePath: detail.activeMembers
                                    .elementAt(index)
                                    .avatarPath,
                                width: 24,
                                height: 24,
                                borderRadius: BorderRadius.circular(14),
                                fallbackBuilder: (_) =>
                                    const _SummaryAvatarFallback(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.outline.withValues(alpha: 0.65), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryHeaderMetric(
                  label: context.l10n.groupSummaryTotalSpent,
                  value: formattedTotal,
                ),
              ),
              Expanded(
                child: _SummaryHeaderMetric(
                  label: balanceLabel,
                  value: formattedBalance,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryHeaderMetric extends StatelessWidget {
  const _SummaryHeaderMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.moniaryTypography.metadata.copyWith(
          color: context.moniaryColors.textDim,
          fontSize: 9,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: context.moniaryTypography.displaySmall.copyWith(fontSize: 17),
      ),
    ],
  );
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({
    required this.budgetAsync,
    required this.spent,
    required this.formatAmount,
  });

  final AsyncValue<GroupBudget> budgetAsync;
  final int spent;
  final String Function(int amount) formatAmount;

  @override
  Widget build(BuildContext context) => budgetAsync.when(
    loading: () => const LinearProgressIndicator(),
    error: (_, _) => const SizedBox.shrink(),
    data: (budget) {
      final colors = context.moniaryColors;
      if (!budget.hasLimit) {
        return MoniaryEditorialCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(context.l10n.groupSummaryBudgetNoLimit)),
            ],
          ),
        );
      }
      final ratio = (spent / budget.monthlyLimit).clamp(0.0, 1.0);
      final exceeded = spent > budget.monthlyLimit;
      final warning =
          spent >= budget.monthlyLimit * budget.warningThresholdPercent / 100;
      final barColor = exceeded
          ? colors.danger
          : warning
          ? colors.warning
          : colors.primary;
      return MoniaryEditorialCard(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.groupSummaryBudgetTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  context.l10n.groupSummaryBudgetSpent(
                    formatAmount(budget.monthlyLimit),
                    formatAmount(spent),
                  ),
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: barColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: colors.outline.withValues(alpha: 0.35),
                color: barColor,
              ),
            ),
            if (warning || exceeded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    exceeded ? Icons.warning_amber_rounded : Icons.info_outline,
                    size: 16,
                    color: barColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exceeded
                          ? context.l10n.groupSummaryBudgetExceeded
                          : context.l10n.groupSummaryBudgetWarning,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: barColor),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _SummaryAvatarFallback extends StatelessWidget {
  const _SummaryAvatarFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.moniaryColors.secondary.withValues(alpha: 0.35),
    child: const Icon(Icons.groups_outlined),
  );
}

class _SummaryCharts extends ConsumerWidget {
  const _SummaryCharts({required this.stats, required this.trendAsync});

  final GroupMonthlyStats stats;
  final AsyncValue<List<GroupMonthlyStats>> trendAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final categories = stats.categoryBreakdown;
    final palette = [
      colors.primary,
      colors.success,
      colors.warning,
      colors.danger,
      colors.textSecondary,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.groupSummaryChartsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (categories.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.groupSummaryCategories,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.groupSummaryCategorySubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 34,
                              sections: [
                                for (
                                  var index = 0;
                                  index < categories.length;
                                  index++
                                )
                                  PieChartSectionData(
                                    value: categories[index].totalAmount
                                        .toDouble(),
                                    color: palette[index % palette.length],
                                    radius: 48,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: [
                              for (
                                var index = 0;
                                index < categories.length;
                                index++
                              )
                                _CategoryLegendRow(
                                  name: categories[index].categoryName,
                                  amount: ref.formatAmount(
                                    categories[index].totalAmount,
                                  ),
                                  percent: stats.totalSpent == 0
                                      ? 0
                                      : categories[index].totalAmount *
                                            100 /
                                            stats.totalSpent,
                                  color: palette[index % palette.length],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        trendAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
          data: (trend) => _TrendChart(trend: trend),
        ),
      ],
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final String name;
  final String amount;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                context.l10n.groupSummaryCategoryShare(percent.round()),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.moniaryColors.textDim,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _TrendChart extends ConsumerWidget {
  const _TrendChart({required this.trend});

  final List<GroupMonthlyStats> trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final maxSpent = trend.fold<int>(
      0,
      (max, item) => item.totalSpent > max ? item.totalSpent : max,
    );
    final interval = maxSpent <= 0 ? 1.0 : maxSpent / 4;
    final chartMax = maxSpent <= 0 ? 1.0 : maxSpent * 1.18;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupSummaryTrendTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              context.l10n.groupSummaryTrendSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textDim),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMax,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.outline.withValues(alpha: 0.45),
                      strokeWidth: 0.8,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < 0 || groupIndex >= trend.length) {
                          return null;
                        }
                        final item = trend[groupIndex];
                        return BarTooltipItem(
                          '${DateFormat('MM/yyyy').format(item.month)}\n'
                          '${ref.formatAmount(item.totalSpent)}\n'
                          '${context.l10n.groupSummaryTransactionCount(item.transactionCount)}',
                          TextStyle(
                            color: colors.surface,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 43,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(
                          _compactAmount(value),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              DateFormat('MM').format(trend[index].month),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < trend.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: trend[index].totalSpent.toDouble(),
                            color: colors.primary,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.groupSummaryTrendTableTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            for (var index = trend.length - 1; index >= 0; index--)
              _TrendDataRow(
                current: trend[index],
                previous: index > 0 ? trend[index - 1] : null,
                formatAmount: ref.formatAmount,
              ),
          ],
        ),
      ),
    );
  }

  String _compactAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class _TrendDataRow extends StatelessWidget {
  const _TrendDataRow({
    required this.current,
    required this.previous,
    required this.formatAmount,
  });

  final GroupMonthlyStats current;
  final GroupMonthlyStats? previous;
  final String Function(int amount) formatAmount;

  @override
  Widget build(BuildContext context) {
    final difference = previous == null || previous!.totalSpent == 0
        ? null
        : ((current.totalSpent - previous!.totalSpent) *
                  100 /
                  previous!.totalSpent)
              .round();
    final change = difference == null
        ? context.l10n.groupTransactionNoChange
        : '${difference > 0 ? '+' : ''}$difference%';
    final changeColor = difference == null || difference == 0
        ? context.moniaryColors.textDim
        : difference > 0
        ? context.moniaryColors.danger
        : context.moniaryColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(DateFormat('MM/yyyy').format(current.month)),
          ),
          Expanded(
            child: Text(
              context.l10n.groupTransactionTrendValue(
                formatAmount(current.totalSpent),
                current.transactionCount,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            change,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: changeColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionSpotlight extends StatelessWidget {
  const _ContributionSpotlight({required this.stats});

  final GroupMonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    final members = [...stats.memberBreakdown]
      ..sort((left, right) {
        final byTransactions = right.transactionCount.compareTo(
          left.transactionCount,
        );
        if (byTransactions != 0) return byTransactions;
        return right.paidAmount.compareTo(left.paidAmount);
      });
    final member = members.first;
    return Card(
      color: context.moniaryColors.primary.withValues(alpha: 0.08),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_awesome_outlined)),
        title: Text(context.l10n.groupSummaryContributionTitle),
        subtitle: Text(
          context.l10n.groupSummaryContributionMessage(member.displayName),
        ),
        trailing: Text(
          context.l10n.groupSummaryContributionCount(member.transactionCount),
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Card(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: context.l10n.groupSummaryPreviousMonth,
          icon: const Icon(Icons.chevron_left_outlined),
        ),
        Text(
          DateFormat('MM/yyyy').format(month),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onNext,
          tooltip: context.l10n.groupSummaryNextMonth,
          icon: const Icon(Icons.chevron_right_outlined),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _SummaryCollapsibleSection extends StatelessWidget {
  const _SummaryCollapsibleSection({
    required this.title,
    required this.child,
    this.count,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final int? count;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: count == null ? null : Text('$count'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        children: [child],
      ),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(18), child: Text(text)),
  );
}

class _SummaryMessage extends StatelessWidget {
  const _SummaryMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}
