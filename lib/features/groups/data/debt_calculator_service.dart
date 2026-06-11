import '../domain/debt_balance.dart';
import '../domain/group_expense.dart';

class DebtCalculatorService {
  const DebtCalculatorService();

  Map<String, int> calculateBalances(List<GroupExpense> expenses) {
    final balances = <String, int>{};
    for (final expense in expenses) {
      balances[expense.payerMemberId] =
          (balances[expense.payerMemberId] ?? 0) + expense.amount;
      for (final split in expense.splits) {
        balances[split.memberId] =
            (balances[split.memberId] ?? 0) - split.amount;
      }
    }
    return balances;
  }

  List<DebtSettlement> simplifyDebts(Map<String, int> balances) {
    final debtors =
        balances.entries
            .where((entry) => entry.value < 0)
            .map((entry) => _Balance(entry.key, -entry.value))
            .toList()
          ..sort((left, right) => right.amount.compareTo(left.amount));
    final creditors =
        balances.entries
            .where((entry) => entry.value > 0)
            .map((entry) => _Balance(entry.key, entry.value))
            .toList()
          ..sort((left, right) => right.amount.compareTo(left.amount));

    final settlements = <DebtSettlement>[];
    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;
      settlements.add(
        DebtSettlement(
          fromMemberId: debtor.memberId,
          toMemberId: creditor.memberId,
          amount: amount,
        ),
      );
      debtor.amount -= amount;
      creditor.amount -= amount;
      if (debtor.amount == 0) {
        debtorIndex++;
      }
      if (creditor.amount == 0) {
        creditorIndex++;
      }
    }
    return settlements;
  }
}

class _Balance {
  _Balance(this.memberId, this.amount);

  final String memberId;
  int amount;
}
