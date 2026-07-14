import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupStatisticsScreen extends ConsumerStatefulWidget {
  const GroupStatisticsScreen({required this.groupId, super.key});

  static const routePath = '/groups/statistics';

  final String groupId;

  @override
  ConsumerState<GroupStatisticsScreen> createState() =>
      _GroupStatisticsScreenState();
}

class _GroupStatisticsScreenState extends ConsumerState<GroupStatisticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final statsKey = (groupId: widget.groupId, month: _month);
    final statsAsync = ref.watch(groupMonthlyStatsProvider(statsKey));
    final budgetAsync = ref.watch(groupBudgetProvider(widget.groupId));
    final historyAsync = ref.watch(
      groupSettlementHistoryProvider(widget.groupId),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê nhóm')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupMonthlyStatsProvider(statsKey));
          ref.invalidate(groupBudgetProvider(widget.groupId));
          ref.invalidate(groupSettlementHistoryProvider(widget.groupId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _MonthSelector(
              month: _month,
              onPrevious: () => setState(() {
                _month = DateTime(_month.year, _month.month - 1);
              }),
              onNext: () => setState(() {
                _month = DateTime(_month.year, _month.month + 1);
              }),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _Notice(
                text: userFriendlyMessage(context, error),
                color: AppTheme.danger,
              ),
              data: (stats) => budgetAsync.when(
                loading: () => _StatsContent(
                  stats: stats,
                  budget: GroupBudget.defaults(widget.groupId),
                  onEditBudget: null,
                  onExport: _exportReport,
                ),
                error: (_, _) => _StatsContent(
                  stats: stats,
                  budget: GroupBudget.defaults(widget.groupId),
                  onEditBudget: null,
                  onExport: _exportReport,
                ),
                data: (budget) => _StatsContent(
                  stats: stats,
                  budget: budget,
                  onEditBudget: () => _editBudget(budget),
                  onExport: _exportReport,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Lịch sử thanh toán nợ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            historyAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _Notice(
                text: userFriendlyMessage(context, error),
                color: AppTheme.danger,
              ),
              data: (history) => _SettlementHistoryList(history: history),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudget(GroupBudget current) async {
    final amountController = TextEditingController(
      text: current.monthlyLimit == 0 ? '' : current.monthlyLimit.toString(),
    );
    final thresholdController = TextEditingController(
      text: current.warningThresholdPercent.toString(),
    );
    final result = await showDialog<GroupBudget>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ngân sách nhóm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ngân sách tháng'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cảnh báo khi đạt (%)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              final threshold =
                  int.tryParse(thresholdController.text.trim()) ?? 80;
              Navigator.pop(
                context,
                current.copyWith(
                  monthlyLimit: amount < 0 ? 0 : amount,
                  warningThresholdPercent: threshold.clamp(1, 100).toInt(),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    amountController.dispose();
    thresholdController.dispose();
    if (result == null) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateBudget(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _exportReport() async {
    try {
      final csv = await ref
          .read(groupActionControllerProvider.notifier)
          .buildGroupReportCsv(widget.groupId);
      final file = File(
        '${Directory.systemTemp.path}/moniary_group_report_${widget.groupId}.csv',
      );
      await file.writeAsString(csv);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'text/csv'),
      ], text: 'Báo cáo nhóm Moniary');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MM/yyyy').format(month),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _StatsContent extends ConsumerWidget {
  const _StatsContent({
    required this.stats,
    required this.budget,
    required this.onEditBudget,
    required this.onExport,
  });

  final GroupMonthlyStats stats;
  final GroupBudget budget;
  final VoidCallback? onEditBudget;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetRatio = budget.hasLimit && budget.monthlyLimit > 0
        ? (stats.totalSpent / budget.monthlyLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final warningAmount =
        budget.monthlyLimit * budget.warningThresholdPercent ~/ 100;
    final overWarning = budget.hasLimit && stats.totalSpent >= warningAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricTile(
              icon: Icons.payments_outlined,
              label: 'Tổng chi tháng',
              value: ref.formatAmount(stats.totalSpent),
            ),
            _MetricTile(
              icon: Icons.receipt_long_outlined,
              label: 'Số giao dịch',
              value: stats.transactionCount.toString(),
            ),
            _MetricTile(
              icon: Icons.category_outlined,
              label: 'Top chi',
              value: stats.topCategoryName ?? 'Chưa có',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ngân sách nhóm',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: onEditBudget,
                      child: const Text('Cập nhật'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  budget.hasLimit
                      ? '${ref.formatAmount(stats.totalSpent)} / ${ref.formatAmount(budget.monthlyLimit)}'
                      : 'Chưa đặt ngân sách tháng.',
                ),
                if (budget.hasLimit) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: budgetRatio,
                    color: overWarning ? AppTheme.amber : AppTheme.success,
                  ),
                  if (overWarning) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Nhóm sắp vượt ngân sách tháng.',
                      style: TextStyle(color: AppTheme.amber),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'Danh mục',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stats.categoryBreakdown.isEmpty)
          const _Notice(
            text: 'Chưa có dữ liệu trong tháng.',
            color: AppTheme.mintSoft,
          )
        else
          ...stats.categoryBreakdown.map(
            (item) => _ProgressRow(
              title: item.categoryName,
              subtitle: '${item.transactionCount} giao dịch',
              amount: item.totalAmount,
              maxAmount: stats.totalSpent,
            ),
          ),
        const SizedBox(height: 22),
        Text('Theo thành viên', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        ...stats.memberBreakdown.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(item.displayName),
              subtitle: Text(
                'Chịu ${ref.formatAmount(item.shareAmount)} • Đã trả ${ref.formatAmount(item.paidAmount)}',
              ),
              trailing: Text(ref.formatAmount(item.balance)),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.mintSoft),
            const SizedBox(height: 10),
            Text(label),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends ConsumerWidget {
  const _ProgressRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.maxAmount,
  });

  final String title;
  final String subtitle;
  final int amount;
  final int maxAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = maxAmount == 0 ? 0.0 : (amount / maxAmount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Text(ref.formatAmount(amount)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSubtle)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}

class _SettlementHistoryList extends ConsumerWidget {
  const _SettlementHistoryList({required this.history});

  final List<GroupSettlementHistoryEntry> history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return const _Notice(
        text: 'Chưa có lịch sử thanh toán nợ.',
        color: AppTheme.mintSoft,
      );
    }
    return Column(
      children: history
          .map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz_outlined),
                title: Text('${item.fromName} trả ${item.toName}'),
                subtitle: Text(
                  '${item.status} • ${DateFormat('dd/MM/yyyy HH:mm').format(item.updatedAt)}',
                ),
                trailing: Text(ref.formatAmount(item.amount)),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
