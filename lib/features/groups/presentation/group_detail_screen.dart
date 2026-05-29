import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
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
      appBar: AppBar(title: Text(context.l10n.groupDetailTitle)),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(context.l10n.groupLoadSingleError)),
        data: (groups) {
          final matching = groups.where((group) => group.id == groupId);
          if (matching.isEmpty) {
            return Center(child: Text(context.l10n.groupNotExists));
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
            Text(
              context.l10n.groupMembersHeader,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: () => _addMember(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(context.l10n.commonAdd),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.members.map((member) {
            return InputChip(
              label: Text(member.displayName),
              avatar: const Icon(Icons.person_outline, size: 16),
              onDeleted: member.id == group.ownerId
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
                label: Text(context.l10n.groupAddExpense),
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
          context.l10n.groupExpenseHistory,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text(
            context.l10n.groupLoadExpensesError,
            style: const TextStyle(color: AppTheme.danger),
          ),
          data: (expenses) => expenses.isEmpty
              ? const _ExpenseEmptyState()
              : Column(
                  children: expenses
                      .map(
                        (expense) => _ExpenseCard(
                          expense: expense,
                          payerName: _nameFor(expense.payerMemberId, context),
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

  String _nameFor(String memberId, BuildContext context) {
    final member = group.members.where((entry) => entry.id == memberId);
    return member.isEmpty
        ? context.l10n.groupDeletedMember
        : member.first.displayName;
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupAddMember),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.l10n.profileSetupDisplayName,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: context.l10n.groupMemberEmailHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonAdd),
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
          SnackBar(content: Text(userFriendlyMessage(context, error))),
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
          SnackBar(content: Text(userFriendlyMessage(context, error))),
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
        title: Text(context.l10n.groupDeleteExpenseConfirmTitle),
        content: Text(context.l10n.groupDeleteExpenseConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.commonDelete),
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
        title: Text(
          expense.note.isEmpty ? context.l10n.groupExpenses : expense.note,
        ),
        subtitle: Text(
          context.l10n.groupPayerSubtitle(
            payerName,
            DateFormat(
              'dd/MM/yyyy',
              Localizations.localeOf(context).toString(),
            ).format(expense.date),
          ),
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
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(context.l10n.commonEdit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.commonDelete),
                ),
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
      child: Text(
        context.l10n.groupEmptyExpensesMessage,
        textAlign: TextAlign.center,
      ),
    );
  }
}
