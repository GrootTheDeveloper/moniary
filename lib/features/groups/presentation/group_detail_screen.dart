import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../application/group_controller.dart';
import '../domain/expense_group.dart';
import '../domain/group_expense.dart';
import 'debt_summary_screen.dart';
import 'group_expense_form_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  static const routePath = '/group-detail';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiêu nhóm')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Không tải được nhóm.')),
        data: (groups) {
          final matching = groups.where((group) => group.id == groupId);
          if (matching.isEmpty) {
            return const Center(child: Text('Nhóm không còn tồn tại.'));
          }
          return _GroupDetailBody(group: matching.first);
        },
      ),
    );
  }
}

class _GroupDetailBody extends ConsumerWidget {
  const _GroupDetailBody({required this.group});

  final ExpenseGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(group.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(group.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thành viên', style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => _addMember(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Thêm'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.members.indexed.map((indexedMember) {
            final index = indexedMember.$1;
            final member = indexedMember.$2;
            return InputChip(
              label: Text(member.displayName),
              avatar: const Icon(Icons.person_outline, size: 16),
              onDeleted: index == 0
                  ? null
                  : () => _removeMember(context, ref, member.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: group.members.length < 2
                    ? null
                    : () => context.push(
                        GroupExpenseFormScreen.routePath,
                        extra: GroupExpenseFormArgs(group: group),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm chi phí'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () =>
                  context.push(DebtSummaryScreen.routePath, extra: group.id),
              child: const Icon(Icons.account_balance_outlined),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Lịch sử chi tiêu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Text(
            'Không tải được chi phí nhóm.',
            style: TextStyle(color: AppTheme.danger),
          ),
          data: (expenses) => expenses.isEmpty
              ? const _ExpenseEmptyState()
              : Column(
                  children: expenses
                      .map(
                        (expense) => _ExpenseCard(
                          expense: expense,
                          payerName: _nameFor(expense.payerMemberId),
                          onEdit: () => context.push(
                            GroupExpenseFormScreen.routePath,
                            extra: GroupExpenseFormArgs(
                              group: group,
                              expense: expense,
                            ),
                          ),
                          onDelete: () => _deleteExpense(context, ref, expense),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  String _nameFor(String memberId) {
    final member = group.members.where((entry) => entry.id == memberId);
    return member.isEmpty ? 'Thành viên đã xóa' : member.first.displayName;
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm thành viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email (không bắt buộc)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    final name = nameController.text;
    final email = emailController.text;
    nameController.dispose();
    emailController.dispose();
    if (result != true || name.trim().isEmpty) {
      return;
    }
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .addMember(groupId: group.id, displayName: name, email: email);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thêm được thành viên: $error')),
        );
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    String memberId,
  ) async {
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .removeMember(groupId: group.id, memberId: memberId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không xóa được thành viên: $error')),
        );
      }
    }
  }

  Future<void> _deleteExpense(
    BuildContext context,
    WidgetRef ref,
    GroupExpense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chi phí?'),
        content: const Text('Thao tác này sẽ cập nhật lại công nợ của nhóm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(groupsControllerProvider.notifier)
          .deleteExpense(expense.id);
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.payerName,
    required this.onEdit,
    required this.onDelete,
  });

  final GroupExpense expense;
  final String payerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(expense.note.isEmpty ? 'Chi phí nhóm' : expense.note),
        subtitle: Text(
          '$payerName đã trả • ${DateFormat('dd/MM/yyyy', 'vi_VN').format(expense.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatVnd(expense.amount),
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseEmptyState extends StatelessWidget {
  const _ExpenseEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: const Text(
        'Chưa có chi phí. Thêm hóa đơn đầu tiên để bắt đầu tính nợ.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
