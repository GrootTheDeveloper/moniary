class DebtSettlement {
  const DebtSettlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
  });

  final String fromMemberId;
  final String toMemberId;
  final double amount;
}
