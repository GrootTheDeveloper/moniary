import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';

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
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Metric(
                        label: context.l10n.groupSummaryTotalSpent,
                        value: ref.formatAmount(stats.totalSpent),
                      ),
                      _Metric(
                        label: context.l10n.groupSummaryTransactions,
                        value: '${stats.transactionCount}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(text: context.l10n.groupSummaryCategories),
              const SizedBox(height: 8),
              if (stats.categoryBreakdown.isEmpty)
                _EmptyCard(text: context.l10n.groupSummaryNoData)
              else
                Card(
                  child: Column(
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
              _SectionTitle(text: context.l10n.groupSummaryMembers),
              const SizedBox(height: 8),
              if (stats.memberBreakdown.isEmpty)
                _EmptyCard(text: context.l10n.groupSummaryNoData)
              else
                Card(
                  child: Column(
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
              _SectionTitle(text: context.l10n.groupSummarySettlementHistory),
              const SizedBox(height: 8),
              historyAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    _EmptyCard(text: userFriendlyMessage(context, error)),
                data: (history) => history.isEmpty
                    ? _EmptyCard(text: context.l10n.groupSummaryNoHistory)
                    : Card(
                        child: Column(
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
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
