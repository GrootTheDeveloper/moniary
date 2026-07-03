import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
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
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserId = ref.watch(currentGroupUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupSettlementTitle)),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () =>
              ref.invalidate(groupSettlementOverviewProvider(groupId)),
        ),
        data: (overview) {
          final active = overview.suggestions
              .where((item) => item.status != GroupSettlementStatus.completed)
              .toList();
          final needPay = active
              .where((item) => item.fromUserId == currentUserId)
              .toList();
          final receive = active
              .where((item) => item.toUserId == currentUserId)
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupSettlementOverviewProvider(groupId));
              ref.invalidate(groupDetailProvider(groupId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
              children: [
                _SettlementHero(
                  groupName: detailAsync.asData?.value.group.name,
                  transactionCount: active.length,
                  needPayTotal: needPay.fold(
                    0,
                    (sum, item) => sum + item.amount,
                  ),
                  receiveTotal: receive.fold(
                    0,
                    (sum, item) => sum + item.amount,
                  ),
                ),
                MoniarySectionLabel(context.l10n.groupYouNeedPay),
                if (needPay.isEmpty)
                  _EmptyCard(text: context.l10n.groupSettlementEmpty)
                else
                  for (var index = 0; index < needPay.length; index++)
                    _SettlementRow(
                      item: needPay[index],
                      showTopDivider: index == 0,
                      isReceiverAction: false,
                      onAction: () =>
                          _markPaid(context, ref, needPay[index].id),
                    ),
                MoniarySectionLabel(context.l10n.groupOthersNeedPayYou),
                if (receive.isEmpty)
                  _EmptyCard(text: context.l10n.groupSettlementEmpty)
                else
                  for (var index = 0; index < receive.length; index++)
                    _SettlementRow(
                      item: receive[index],
                      showTopDivider: index == 0,
                      isReceiverAction: true,
                      onAction: () =>
                          _confirmReceived(context, ref, receive[index].id),
                    ),
                MoniarySectionLabel(context.l10n.groupBalanceTableTitle),
                if (overview.balances.isEmpty)
                  _EmptyCard(text: context.l10n.debtNoData)
                else
                  for (var index = 0; index < overview.balances.length; index++)
                    _BalanceRow(
                      balance: overview.balances[index],
                      showTopDivider: index == 0,
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

class _SettlementHero extends StatelessWidget {
  const _SettlementHero({
    required this.groupName,
    required this.transactionCount,
    required this.needPayTotal,
    required this.receiveTotal,
  });

  final String? groupName;
  final int transactionCount;
  final int needPayTotal;
  final int receiveTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return MoniaryEditorialCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName ?? context.l10n.groupSettlementTitle,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.transactionCount(transactionCount).toUpperCase(),
            style: context.moniaryTypography.metadata,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: context.l10n.groupYouNeedPay,
                  amount: needPayTotal,
                  color: colors.danger,
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: colors.textPrimary.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: _HeroMetric(
                    label: context.l10n.groupOthersNeedPayYou,
                    amount: receiveTotal,
                    color: colors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formatVnd(amount),
          style: context.moniaryTypography.displaySmall.copyWith(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({
    required this.item,
    required this.showTopDivider,
    required this.isReceiverAction,
    required this.onAction,
  });

  final GroupSettlementSuggestion item;
  final bool showTopDivider;
  final bool isReceiverAction;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: showTopDivider
              ? BorderSide(
                  color: context.moniaryColors.textPrimary.withValues(
                    alpha: 0.12,
                  ),
                )
              : BorderSide.none,
          bottom: BorderSide(
            color: context.moniaryColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fromDisplayName ?? context.l10n.groupUnknownMember,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: context.moniaryColors.textDim,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.toDisplayName ?? context.l10n.groupUnknownMember,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                formatVnd(item.amount),
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: context.moniaryColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              MoniaryDotBadge(color: _statusColor(context, item.status)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _statusLabel(context, item.status).toUpperCase(),
                  style: context.moniaryTypography.metadata,
                ),
              ),
              SizedBox(
                width: 156,
                child: SettlementActionButton(
                  status: item.status,
                  isReceiverAction: isReceiverAction,
                  onPressed: onAction,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context, GroupSettlementStatus status) {
    return switch (status) {
      GroupSettlementStatus.completed => context.moniaryColors.success,
      GroupSettlementStatus.disputed => context.moniaryColors.danger,
      _ => context.moniaryColors.warning,
    };
  }

  String _statusLabel(BuildContext context, GroupSettlementStatus status) {
    return switch (status) {
      GroupSettlementStatus.pending => context.l10n.groupSettlementPending,
      GroupSettlementStatus.payerMarkedPaid =>
        context.l10n.groupSettlementPayerMarked,
      GroupSettlementStatus.completed => context.l10n.groupSettlementCompleted,
      GroupSettlementStatus.disputed => context.l10n.groupSettlementDisputed,
    };
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.showTopDivider});

  final GroupBalance balance;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final valueColor = balance.balance == 0
        ? context.moniaryColors.textDim
        : balance.balance > 0
        ? context.moniaryColors.danger
        : context.moniaryColors.success;

    return MoniaryHairlineTile(
      showTopDivider: showTopDivider,
      title: Text(balance.displayName ?? context.l10n.groupUnknownMember),
      subtitle: Text(
        context.l10n.groupSharePaidBalance(
          formatVnd(balance.totalShareAmount),
          formatVnd(balance.totalPaidAmount),
          formatVnd(balance.balance),
        ),
      ),
      trailing: Text(
        formatVnd(balance.balance.abs()),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: valueColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MoniaryEditorialCard(
      backgroundColor: context.moniaryColors.surface.withValues(alpha: 0.65),
      child: Text(text),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
      ),
    );
  }
}
