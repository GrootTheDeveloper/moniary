import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
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
      appBar: AppBar(title: const Text('Tổng kết công nợ')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Không tải được nhóm.')),
        data: (groups) {
          final matches = groups.where((group) => group.id == groupId);
          if (matches.isEmpty) {
            return const Center(child: Text('Không tìm thấy nhóm.'));
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
          const Center(child: Text('Không tính được công nợ.')),
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
              'Số dương là số tiền cần nhận, số âm là số tiền cần trả.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ...group.members.map((member) {
              final value = balances[member.id] ?? 0;
              return _BalanceCard(name: member.displayName, value: value);
            }),
            const SizedBox(height: 22),
            Text(
              'Gợi ý thanh toán',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (settlements.isEmpty)
              const _SettledCard()
            else
              ...settlements.map(
                (settlement) => _SettlementCard(
                  text:
                      '${_name(settlement.fromMemberId)} trả ${_name(settlement.toMemberId)}',
                  amount: settlement.amount,
                ),
              ),
          ],
        );
      },
    );
  }

  String _name(String memberId) {
    final member = group.members.where((entry) => entry.id == memberId);
    return member.isEmpty ? 'Thành viên' : member.first.displayName;
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
        subtitle: Text(positive ? 'Sẽ nhận' : 'Cần trả'),
        trailing: Text(
          '${positive ? '+' : '-'}${_money(value.abs())}',
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
            _money(amount),
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
      child: const Text(
        'Không có khoản cần thanh toán.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.success),
      ),
    );
  }
}

String _money(double value) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(value);
}
