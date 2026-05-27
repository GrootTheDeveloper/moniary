import '../domain/expense_group.dart';
import '../domain/expense_split.dart';
import '../domain/group_expense.dart';
import '../domain/group_member.dart';

abstract interface class GroupExpenseService {
  Future<List<ExpenseGroup>> fetchGroups();

  Future<List<GroupExpense>> fetchExpenses(String groupId);

  Future<void> createGroup({required String name, required String ownerId});

  Future<void> addMember({
    required String groupId,
    required String displayName,
    String? email,
  });

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  });

  Future<void> saveExpense({
    String? expenseId,
    required String groupId,
    required String payerMemberId,
    required double amount,
    required String note,
    required DateTime date,
    required List<ExpenseSplit> splits,
  });

  Future<void> deleteExpense(String expenseId);
}

class InMemoryGroupExpenseService implements GroupExpenseService {
  final List<ExpenseGroup> _groups = [];
  final List<GroupExpense> _expenses = [];
  var _nextId = 0;

  @override
  Future<List<ExpenseGroup>> fetchGroups() async {
    return List.unmodifiable(_groups);
  }

  @override
  Future<List<GroupExpense>> fetchExpenses(String groupId) async {
    final entries =
        _expenses.where((expense) => expense.groupId == groupId).toList()
          ..sort((left, right) => right.date.compareTo(left.date));
    return List.unmodifiable(entries);
  }

  @override
  Future<void> createGroup({
    required String name,
    required String ownerId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Tên nhóm không được để trống.');
    }
    final ownerMember = GroupMember(id: _id('member'), displayName: 'Bạn');
    _groups.add(
      ExpenseGroup(
        id: _id('group'),
        name: trimmedName,
        ownerId: ownerId,
        createdAt: DateTime.now(),
        members: [ownerMember],
      ),
    );
  }

  @override
  Future<void> addMember({
    required String groupId,
    required String displayName,
    String? email,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw ArgumentError('Tên thành viên không được để trống.');
    }
    final index = _groupIndex(groupId);
    final current = _groups[index];
    final members = [
      ...current.members,
      GroupMember(
        id: _id('member'),
        displayName: name,
        email: email?.trim().isEmpty == true ? null : email?.trim(),
      ),
    ];
    _groups[index] = current.copyWith(members: members);
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    final index = _groupIndex(groupId);
    final group = _groups[index];
    final usedInExpense = _expenses
        .where((expense) => expense.groupId == groupId)
        .any(
          (expense) =>
              expense.payerMemberId == memberId ||
              expense.splits.any((split) => split.memberId == memberId),
        );
    if (usedInExpense) {
      throw StateError('Không thể xóa thành viên đã có chi phí liên quan.');
    }
    _groups[index] = group.copyWith(
      members: group.members.where((member) => member.id != memberId).toList(),
    );
  }

  @override
  Future<void> saveExpense({
    String? expenseId,
    required String groupId,
    required String payerMemberId,
    required double amount,
    required String note,
    required DateTime date,
    required List<ExpenseSplit> splits,
  }) async {
    _groupIndex(groupId);
    final entry = GroupExpense(
      id: expenseId ?? _id('expense'),
      groupId: groupId,
      payerMemberId: payerMemberId,
      amount: amount,
      note: note.trim(),
      date: date,
      splits: List.unmodifiable(splits),
    );
    if (expenseId == null) {
      _expenses.add(entry);
      return;
    }
    final index = _expenses.indexWhere((expense) => expense.id == expenseId);
    if (index == -1) {
      throw StateError('Không tìm thấy chi phí cần sửa.');
    }
    _expenses[index] = entry;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _expenses.removeWhere((expense) => expense.id == expenseId);
  }

  int _groupIndex(String groupId) {
    final index = _groups.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      throw StateError('Không tìm thấy nhóm.');
    }
    return index;
  }

  String _id(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';
}
