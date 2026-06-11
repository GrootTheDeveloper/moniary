import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../widgets/settlement_action_button.dart';

class DebtSettlementScreen extends ConsumerWidget {
  const DebtSettlementScreen({required this.groupId, super.key});

  static const routePath = '/groups/settlements';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(groupSettlementOverviewProvider(groupId));
    final currentUserId = ref.watch(currentGroupUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupSettlementTitle)),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (overview) {
          final needPay = overview.suggestions
              .where((item) => item.fromUserId == currentUserId)
              .toList();
          final receive = overview.suggestions
              .where((item) => item.toUserId == currentUserId)
              .toList();
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(groupSettlementOverviewProvider(groupId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Text(
                  context.l10n.groupBalanceTableTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (overview.balances.isEmpty)
                  _EmptyCard(text: context.l10n.debtNoData)
                else
                  ...overview.balances.map(
                    (balance) => _BalanceRow(balance: balance),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.groupYouNeedPay,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (needPay.isEmpty)
                  _EmptyCard(text: context.l10n.groupSettlementEmpty)
                else
                  ...needPay.map(
                    (item) => _SettlementCard(
                      item: item,
                      isReceiverAction: false,
                      onAction: () => _markPaid(context, ref, item.id),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.groupOthersNeedPayYou,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (receive.isEmpty)
                  _EmptyCard(text: context.l10n.groupSettlementEmpty)
                else
                  ...receive.map(
                    (item) => _SettlementCard(
                      item: item,
                      isReceiverAction: true,
                      onAction: () => _confirmReceived(context, ref, item.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .markSettlementPaid(settlementId: settlementId, groupId: groupId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _confirmReceived(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .confirmSettlementReceived(
            settlementId: settlementId,
            groupId: groupId,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance});

  final GroupBalance balance;

  @override
  Widget build(BuildContext context) {
    final color = balance.balance == 0
        ? AppTheme.success
        : balance.balance > 0
        ? AppTheme.danger
        : AppTheme.mintSoft;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        title: Text(balance.displayName ?? context.l10n.groupUnknownMember),
        subtitle: Text(
          context.l10n.groupSharePaidBalance(
            formatVnd(balance.totalShareAmount),
            formatVnd(balance.totalPaidAmount),
            formatVnd(balance.balance),
          ),
        ),
        trailing: Icon(Icons.circle_outlined, color: color),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({
    required this.item,
    required this.isReceiverAction,
    required this.onAction,
  });

  final GroupSettlementSuggestion item;
  final bool isReceiverAction;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupSettlementFromTo(
                item.fromDisplayName ?? context.l10n.groupUnknownMember,
                item.toDisplayName ?? context.l10n.groupUnknownMember,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              formatVnd(item.amount),
              style: const TextStyle(
                color: AppTheme.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(_statusLabel(context, item.status)),
            const SizedBox(height: 12),
            SettlementActionButton(
              status: item.status,
              isReceiverAction: isReceiverAction,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, GroupSettlementStatus status) =>
      switch (status) {
        GroupSettlementStatus.pending => context.l10n.groupSettlementPending,
        GroupSettlementStatus.payerMarkedPaid =>
          context.l10n.groupSettlementPayerMarked,
        GroupSettlementStatus.completed =>
          context.l10n.groupSettlementCompleted,
        GroupSettlementStatus.disputed => context.l10n.groupSettlementDisputed,
      };
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text),
    );
  }
}
