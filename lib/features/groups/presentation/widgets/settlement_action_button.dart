import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_enums.dart';

class SettlementActionButton extends StatelessWidget {
  const SettlementActionButton({
    required this.status,
    required this.isReceiverAction,
    required this.onPressed,
    super.key,
  });

  final GroupSettlementStatus status;
  final bool isReceiverAction;
  final VoidCallback onPressed;

  bool get isEnabled => isReceiverAction
      ? status == GroupSettlementStatus.payerMarkedPaid
      : status == GroupSettlementStatus.pending;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: ValueKey(
        isReceiverAction
            ? 'confirm-settlement-received'
            : 'mark-settlement-paid',
      ),
      onPressed: isEnabled ? onPressed : null,
      child: Text(
        isReceiverAction
            ? context.l10n.groupConfirmReceived
            : context.l10n.groupMarkPaid,
      ),
    );
  }
}
