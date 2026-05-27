import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_expense_service.dart';
import '../domain/expense_group.dart';
import '../domain/expense_split.dart';
import '../domain/group_expense.dart';

final groupExpenseServiceProvider = Provider<GroupExpenseService>((ref) {
  return InMemoryGroupExpenseService();
});

final groupsControllerProvider =
    AsyncNotifierProvider<GroupsController, List<ExpenseGroup>>(
      GroupsController.new,
    );

final groupExpensesProvider = FutureProvider.family<List<GroupExpense>, String>(
  (ref, groupId) async {
    ref.watch(groupsControllerProvider);
    return ref.watch(groupExpenseServiceProvider).fetchExpenses(groupId);
  },
);

class GroupsController extends AsyncNotifier<List<ExpenseGroup>> {
  @override
  Future<List<ExpenseGroup>> build() {
    return ref.read(groupExpenseServiceProvider).fetchGroups();
  }

  Future<void> createGroup({
    required String name,
    required String ownerId,
  }) async {
    await ref
        .read(groupExpenseServiceProvider)
        .createGroup(name: name, ownerId: ownerId);
    await _reload();
  }

  Future<void> addMember({
    required String groupId,
    required String displayName,
    String? email,
  }) async {
    await ref
        .read(groupExpenseServiceProvider)
        .addMember(groupId: groupId, displayName: displayName, email: email);
    await _reload();
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    await ref
        .read(groupExpenseServiceProvider)
        .removeMember(groupId: groupId, memberId: memberId);
    await _reload();
  }

  Future<void> saveExpense({
    String? expenseId,
    required String groupId,
    required String payerMemberId,
    required double amount,
    required String note,
    required DateTime date,
    required List<ExpenseSplit> splits,
  }) async {
    await ref
        .read(groupExpenseServiceProvider)
        .saveExpense(
          expenseId: expenseId,
          groupId: groupId,
          payerMemberId: payerMemberId,
          amount: amount,
          note: note,
          date: date,
          splits: splits,
        );
    await _reload();
  }

  Future<void> deleteExpense(String expenseId) async {
    await ref.read(groupExpenseServiceProvider).deleteExpense(expenseId);
    await _reload();
  }

  Future<void> _reload() async {
    state = AsyncData(
      await ref.read(groupExpenseServiceProvider).fetchGroups(),
    );
  }
}
