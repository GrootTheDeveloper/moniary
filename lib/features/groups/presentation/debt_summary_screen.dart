import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../application/group_controller.dart';
import '../data/debt_calculator_service.dart';
import '../domain/expense_group.dart';

class DebtSummaryScreen extends ConsumerWidget {
  const DebtSummaryScreen({required this.groupId, super.key});

  static const routePath = '/debt-summary';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.debtSummaryAppBarTitle)),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(context.l10n.groupLoadSingleError)),
        data: (groups) {
          final matches = groups.where((group) => group.id == groupId);
          if (matches.isEmpty) {
            return Center(child: Text(context.l10n.groupNotExists));
          }
          return _DebtBody(group: matches.first);
        },
      ),
    );
  }
}

class _DebtBody extends ConsumerWidget {
  const _DebtBody({required this.group});

  final ExpenseGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));
    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(context.l10n.debtLoadError)),
      data: (expenses) {
        final calculator = const DebtCalculatorService();
        final balances = calculator.calculateBalances(expenses);
        final settlements = calculator.simplifyDebts(balances);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(group.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              context.l10n.debtExplanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ...group.members.map((member) {
              final value = balances[member.id] ?? 0;
              return _BalanceCard(name: member.displayName, value: value);
            }),
            const SizedBox(height: 22),
            Text(
              context.l10n.debtSettlementTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (settlements.isEmpty)
              const _SettledCard()
            else
              ...settlements.map(
                (settlement) => _SettlementCard(
                  text: context.l10n.debtOwesPayerToPayee(
                    _name(settlement.fromMemberId, context),
                    _name(settlement.toMemberId, context),
                  ),
                  amount: settlement.amount,
                ),
              ),
          ],
        );
      },
    );
  }

  String _name(String memberId, BuildContext context) {
    final member = group.members.where((entry) => entry.id == memberId);
    return member.isEmpty ? context.l10n.debtMember : member.first.displayName;
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.name, required this.value});

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppTheme.success : AppTheme.danger;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.16),
          foregroundColor: color,
          child: Icon(positive ? Icons.arrow_downward : Icons.arrow_upward),
        ),
        title: Text(name),
        subtitle: Text(positive ? context.l10n.debtToReceive : context.l10n.debtToPay),
        trailing: Text(
          '${positive ? '+' : '-'}${formatVnd(value.abs())}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.text, required this.amount});

  final String text;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          Text(
            formatVnd(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SettledCard extends StatelessWidget {
  const _SettledCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        context.l10n.debtNoSettlement,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.success),
      ),
    );
  }
}
