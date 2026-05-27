import 'expense_split.dart';

class GroupExpense {
  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.payerMemberId,
    required this.amount,
    required this.note,
    required this.date,
    this.splits = const [],
  });

  final String id;
  final String groupId;
  final String payerMemberId;
  final double amount;
  final String note;
  final DateTime date;
  final List<ExpenseSplit> splits;
}
