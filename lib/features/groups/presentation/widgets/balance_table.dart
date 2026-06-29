import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../domain/entities/group_settlement.dart';

class BalanceTable extends StatelessWidget {
  const BalanceTable({required this.balances, super.key});

  final List<GroupBalance> balances;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: balances
          .map((balance) => _BalanceRow(balance: balance))
          .toList(),
    );
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
