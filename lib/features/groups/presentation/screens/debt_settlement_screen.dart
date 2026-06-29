import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../widgets/balance_table.dart';
import '../widgets/settlement_suggestion_card.dart';

class DebtSettlementScreen extends ConsumerWidget {
  const DebtSettlementScreen({required this.groupId, super.key});

  static const routePath = '/groups/settlements';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(groupSettlementOverviewProvider(groupId));
    final currentUserId = ref.watch(currentGroupUserIdProvider);
    final role = ref
        .watch(groupDetailProvider(groupId))
        .asData
        ?.value
        .currentUserRole;
    final canResetDisputed = role == GroupRole.owner || role == GroupRole.admin;
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
          final disputedReview = canResetDisputed
              ? overview.suggestions
                    .where(
                      (item) =>
                          item.status == GroupSettlementStatus.disputed &&
                          item.fromUserId != currentUserId &&
                          item.toUserId != currentUserId,
                    )
                    .toList()
              : <GroupSettlementSuggestion>[];
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
                  BalanceTable(balances: overview.balances),
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
                    (item) => SettlementSuggestionCard(
                      suggestion: item,
                      currentUserId: currentUserId,
                      canResetDisputed: canResetDisputed,
                      onMarkPaid: () => _markPaid(context, ref, item.id),
                      onConfirmReceived: () =>
                          _confirmReceived(context, ref, item.id),
                      onDispute: () => _dispute(context, ref, item.id),
                      onReset: () => _resetDisputed(context, ref, item.id),
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
                    (item) => SettlementSuggestionCard(
                      suggestion: item,
                      currentUserId: currentUserId,
                      canResetDisputed: canResetDisputed,
                      onMarkPaid: () => _markPaid(context, ref, item.id),
                      onConfirmReceived: () =>
                          _confirmReceived(context, ref, item.id),
                      onDispute: () => _dispute(context, ref, item.id),
                      onReset: () => _resetDisputed(context, ref, item.id),
                    ),
                  ),
                if (disputedReview.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Đang tranh chấp',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ...disputedReview.map(
                    (item) => SettlementSuggestionCard(
                      suggestion: item,
                      currentUserId: currentUserId,
                      canResetDisputed: canResetDisputed,
                      onMarkPaid: () => _markPaid(context, ref, item.id),
                      onConfirmReceived: () =>
                          _confirmReceived(context, ref, item.id),
                      onDispute: () => _dispute(context, ref, item.id),
                      onReset: () => _resetDisputed(context, ref, item.id),
                    ),
                  ),
                ],
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

  Future<void> _dispute(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Bạn có chắc muốn tranh chấp khoản thanh toán này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận tranh chấp'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .disputeSettlement(settlementId: settlementId, groupId: groupId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _resetDisputed(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .resetDisputedSettlement(
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
