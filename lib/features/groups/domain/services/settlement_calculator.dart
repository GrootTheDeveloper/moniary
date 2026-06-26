class SettlementDraft {
  const SettlementDraft({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });

  final String fromUserId;
  final String toUserId;
  final int amount;
}

class SettlementCalculator {
  const SettlementCalculator();

  List<SettlementDraft> calculate(Map<String, int> balances) {
    final total = balances.values.fold<int>(0, (sum, balance) => sum + balance);
    if (total != 0) {
      throw ArgumentError.value(
        balances,
        'balances',
        'Total debt must equal total credit.',
      );
    }

    final debtors =
        balances.entries
            .where((entry) => entry.value > 0)
            .map((entry) => _MutableBalance(entry.key, entry.value))
            .toList()
          ..sort(_descending);
    final creditors =
        balances.entries
            .where((entry) => entry.value < 0)
            .map((entry) => _MutableBalance(entry.key, entry.value))
            .toList()
          ..sort(_ascending);

    final suggestions = <SettlementDraft>[];
    var debtorIndex = 0;
    var creditorIndex = 0;
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];
      final amount = debtor.amount < -creditor.amount
          ? debtor.amount
          : -creditor.amount;
      suggestions.add(
        SettlementDraft(
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amount: amount,
        ),
      );
      debtor.amount -= amount;
      creditor.amount += amount;
      if (debtor.amount == 0) {
        debtorIndex++;
      }
      if (creditor.amount == 0) {
        creditorIndex++;
      }
    }
    return List.unmodifiable(suggestions);
  }

  static int _descending(_MutableBalance left, _MutableBalance right) {
    final byAmount = right.amount.compareTo(left.amount);
    return byAmount != 0 ? byAmount : left.userId.compareTo(right.userId);
  }

  static int _ascending(_MutableBalance left, _MutableBalance right) {
    final byAmount = left.amount.compareTo(right.amount);
    return byAmount != 0 ? byAmount : left.userId.compareTo(right.userId);
  }
}

class _MutableBalance {
  _MutableBalance(this.userId, this.amount);

  final String userId;
  int amount;
}
