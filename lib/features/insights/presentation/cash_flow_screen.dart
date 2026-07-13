import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../../recurring/domain/recurring_materializer.dart';
import '../../recurring/presentation/recurring_list_screen.dart';
import '../application/net_worth_provider.dart';
import '../domain/cash_flow_projection.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  static const routePath = '/cash-flow';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final forecastAsync = ref.watch(cashFlowForecastProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(context.l10n.cashFlowTitle)),
      body: forecastAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.mint),
        ),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (forecast) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(netWorthProvider);
            ref.invalidate(cashFlowForecastProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _NetWorthCard(total: forecast.startingBalance),
              const SizedBox(height: 16),
              _WalletBreakdown(),
              const SizedBox(height: 20),
              _HorizonSelector(),
              const SizedBox(height: 12),
              _ProjectionCard(forecast: forecast),
              const SizedBox(height: 20),
              _UpcomingSection(upcoming: forecast.upcoming),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.push(RecurringListScreen.routePath),
                icon: const Icon(Icons.event_repeat_outlined),
                label: Text(context.l10n.cashFlowManageRecurring),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.netWorthTitle.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: colors.textDim,
            ),
          ),
          const SizedBox(height: 8),
          ObscurableAmountText(
            amountText: _money(context, total),
            style: context.moniaryTypography.displayLarge.copyWith(
              fontSize: 40,
              color: total >= 0 ? colors.primary : AppTheme.danger,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.netWorthSubtitle,
            style: TextStyle(color: colors.textDim, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WalletBreakdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final snapshot = ref.watch(netWorthProvider).asData?.value;
    if (snapshot == null || snapshot.wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.cashFlowWalletsTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final balance in snapshot.wallets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColor.fromHex(
                        balance.wallet.color,
                        fallback: AppTheme.mint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      balance.wallet.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  ObscurableAmountText(
                    amountText: _money(context, balance.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: balance.balance >= 0
                          ? colors.textPrimary
                          : AppTheme.danger,
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

class _HorizonSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizon = ref.watch(cashFlowHorizonProvider);
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 30, label: Text('30')),
        ButtonSegment(value: 60, label: Text('60')),
        ButtonSegment(value: 90, label: Text('90')),
      ],
      selected: {horizon},
      onSelectionChanged: (selection) =>
          ref.read(cashFlowHorizonProvider.notifier).set(selection.first),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({required this.forecast});

  final CashFlowForecast forecast;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final summary = forecast.summary;
    final horizon = forecast.points.isEmpty
        ? 0
        : forecast.points.last.date
              .difference(forecast.points.first.date)
              .inDays;
    final locale = Localizations.localeOf(context).toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.cashFlowProjectedTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.cashFlowInDays(horizon),
            style: TextStyle(color: colors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: _Chart(points: forecast.points)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: context.l10n.cashFlowProjectedTitle,
                  amount: summary.endingBalance,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: context.l10n.cashFlowNetChange,
                  amount: summary.netChange,
                  signed: true,
                ),
              ),
            ],
          ),
          if (summary.dipsBelowZero) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: AppTheme.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.cashFlowDipWarning(
                        DateFormat.yMMMd(locale).format(summary.lowestDate),
                      ),
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.points});

  final List<CashFlowPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    if (points.length < 2) {
      return Center(
        child: Text(
          context.l10n.cashFlowEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textDim, fontSize: 13),
        ),
      );
    }

    final start = points.first.date;
    final spots = [
      for (final point in points)
        FlSpot(point.date.difference(start).inDays.toDouble(), point.balance),
    ];

    var minY = points.first.balance;
    var maxY = points.first.balance;
    for (final point in points) {
      if (point.balance < minY) minY = point.balance;
      if (point.balance > maxY) maxY = point.balance;
    }
    if (minY > 0) minY = 0;
    final span = (maxY - minY).abs();
    final pad = span == 0 ? 1.0 : span * 0.12;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (minY < 0)
              HorizontalLine(
                y: 0,
                color: AppTheme.danger.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: colors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    this.signed = false,
  });

  final String label;
  final double amount;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final color = signed
        ? (amount >= 0 ? AppTheme.success : AppTheme.danger)
        : colors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.textDim)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ObscurableAmountText(
            prefixText: signed && amount >= 0 ? '+' : '',
            amountText: _money(context, amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.upcoming});

  final List<PostedOccurrence> upcoming;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toString();
    final items = upcoming.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.cashFlowUpcomingTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      DateFormat.MMMd(locale).format(item.date),
                      style: TextStyle(color: colors.textDim, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (item.rule.note?.trim().isNotEmpty ?? false)
                          ? item.rule.note!.trim()
                          : item.rule.categoryName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  ObscurableAmountText(
                    prefixText: item.rule.isIncome ? '+' : '-',
                    amountText: _money(context, item.rule.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.rule.isIncome
                          ? AppTheme.success
                          : AppTheme.danger,
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

String _money(BuildContext context, double amount) => formatMoney(amount);
