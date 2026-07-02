import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import 'settlement_action_button.dart';

class SettlementSuggestionCard extends StatelessWidget {
  const SettlementSuggestionCard({
    required this.suggestion,
    required this.currentUserId,
    required this.canResetDisputed,
    required this.onMarkPaid,
    required this.onConfirmReceived,
    required this.onDispute,
    required this.onReset,
    super.key,
  });

  final GroupSettlementSuggestion suggestion;
  final String currentUserId;
  final bool canResetDisputed;
  final VoidCallback onMarkPaid;
  final VoidCallback onConfirmReceived;
  final VoidCallback onDispute;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isPayerAction = suggestion.fromUserId == currentUserId;
    final isReceiverAction = suggestion.toUserId == currentUserId;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.groupSettlementFromTo(
                suggestion.fromDisplayName ?? context.l10n.groupUnknownMember,
                suggestion.toDisplayName ?? context.l10n.groupUnknownMember,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              formatVnd(suggestion.amount),
              style: const TextStyle(
                color: AppTheme.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _statusLabel(context, suggestion.status),
              style: suggestion.status == GroupSettlementStatus.disputed
                  ? const TextStyle(color: AppTheme.danger)
                  : null,
            ),
            const SizedBox(height: 12),
            _actions(
              isPayerAction: isPayerAction,
              isReceiverAction: isReceiverAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions({
    required bool isPayerAction,
    required bool isReceiverAction,
  }) {
    if (suggestion.status == GroupSettlementStatus.disputed) {
      if (!canResetDisputed) {
        return const SizedBox.shrink();
      }
      return FilledButton(
        key: const ValueKey('reset-disputed-settlement'),
        onPressed: onReset,
        child: const Text('Đặt lại'),
      );
    }

    if (isReceiverAction &&
        suggestion.status == GroupSettlementStatus.payerMarkedPaid) {
      return Row(
        children: [
          Expanded(
            child: SettlementActionButton(
              status: suggestion.status,
              isReceiverAction: true,
              onPressed: onConfirmReceived,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('dispute-settlement'),
              onPressed: onDispute,
              child: const Text('Tranh chấp'),
            ),
          ),
        ],
      );
    }

    if (isPayerAction || isReceiverAction) {
      return SettlementActionButton(
        status: suggestion.status,
        isReceiverAction: isReceiverAction,
        onPressed: isReceiverAction ? onConfirmReceived : onMarkPaid,
      );
    }

    return const SizedBox.shrink();
  }

  String _statusLabel(BuildContext context, GroupSettlementStatus status) =>
      switch (status) {
        GroupSettlementStatus.pending => context.l10n.groupSettlementPending,
        GroupSettlementStatus.payerMarkedPaid =>
          context.l10n.groupSettlementPayerMarked,
        GroupSettlementStatus.completed =>
          context.l10n.groupSettlementCompleted,
        GroupSettlementStatus.disputed => 'Đang tranh chấp',
      };
}
