import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../application/group_controller.dart';
import '../data/group_expense_validation_service.dart';
import '../domain/expense_group.dart';
import '../domain/expense_split.dart';
import '../domain/group_expense.dart';

class GroupExpenseFormArgs {
  const GroupExpenseFormArgs({required this.group, this.expense});

  final ExpenseGroup group;
  final GroupExpense? expense;
}

class GroupExpenseFormScreen extends ConsumerStatefulWidget {
  const GroupExpenseFormScreen({required this.args, super.key});

  static const routePath = '/group-expense-form';

  final GroupExpenseFormArgs args;

  @override
  ConsumerState<GroupExpenseFormScreen> createState() =>
      _GroupExpenseFormScreenState();
}

class _GroupExpenseFormScreenState
    extends ConsumerState<GroupExpenseFormScreen> {
  final _validator = const GroupExpenseValidationService();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final Map<String, TextEditingController> _manualControllers = {};
  late DateTime _date;
  String? _payerMemberId;
  late Set<String> _participants;
  late SplitMethod _method;
  bool _saving = false;

  ExpenseGroup get _group => widget.args.group;

  @override
  void initState() {
    super.initState();
    final expense = widget.args.expense;
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.round().toString(),
    );
    _noteController = TextEditingController(text: expense?.note ?? '');
    _date = expense?.date ?? DateTime.now();
    _payerMemberId =
        expense?.payerMemberId ??
        (_group.members.isEmpty ? null : _group.members.first.id);
    _participants = expense == null
        ? _group.members.map((member) => member.id).toSet()
        : expense.splits.map((split) => split.memberId).toSet();
    _method = expense == null ? SplitMethod.equal : SplitMethod.manual;
    for (final member in _group.members) {
      final matchingSplits =
          expense?.splits
              .where((value) => value.memberId == member.id)
              .toList() ??
          const [];
      final split = matchingSplits.isEmpty ? null : matchingSplits.first;
      _manualControllers[member.id] = TextEditingController(
        text: split == null ? '' : split.amount.round().toString(),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    for (final controller in _manualControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _readAmount(_amountController.text);
    final equalSplits = _validator.createEqualSplits(
      amount: amount,
      participantIds: _participants.toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.args.expense == null
              ? context.l10n.expenseFormTitle
              : context.l10n.expenseFormEditTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          if (_group.members.length < 2)
            _Notice(text: context.l10n.expenseFormMinMembersNotice),
          TextField(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.expenseFormTotalCost,
              suffixText: context.l10n.transactionAmountSuffix,
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: context.l10n.expenseFormContentLabel,
              prefixIcon: const Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _payerMemberId,
            items: _group.members
                .map(
                  (member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _payerMemberId = value),
            decoration: InputDecoration(
              labelText: context.l10n.expenseFormPayer,
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            onTap: _pickDate,
            tileColor: AppTheme.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppTheme.outline),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(context.l10n.expenseFormDate),
            trailing: Text(
              DateFormat(
                'dd/MM/yyyy',
                Localizations.localeOf(context).toString(),
              ).format(_date),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.expenseParticipants,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._group.members.map(
            (member) => CheckboxListTile(
              value: _participants.contains(member.id),
              title: Text(member.displayName),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.mint,
              onChanged: (selected) {
                setState(() {
                  if (selected ?? false) {
                    _participants.add(member.id);
                  } else {
                    _participants.remove(member.id);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<SplitMethod>(
            segments: SplitMethod.values
                .map(
                  (method) => ButtonSegment(
                    value: method,
                    label: Text(method.getLabel(context.l10n)),
                  ),
                )
                .toList(),
            selected: {_method},
            onSelectionChanged: (selected) =>
                setState(() => _method = selected.first),
          ),
          const SizedBox(height: 14),
          if (_method == SplitMethod.equal)
            ...equalSplits.map(
              (split) => _ShareRow(
                name: _memberName(split.memberId),
                value: formatVnd(split.amount),
              ),
            )
          else
            ..._group.members
                .where((member) => _participants.contains(member.id))
                .map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: _manualControllers[member.id],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: member.displayName,
                        suffixText: context.l10n.transactionAmountSuffix,
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? context.l10n.commonSaving : context.l10n.expenseSave,
            ),
          ),
        ],
      ),
    );
  }

  String _memberName(String id) {
    return _group.members.firstWhere((member) => member.id == id).displayName;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _save() async {
    final amount = _readAmount(_amountController.text);
    final participantIds = _participants.toList();
    final splits = _method == SplitMethod.equal
        ? _validator.createEqualSplits(
            amount: amount,
            participantIds: participantIds,
          )
        : participantIds
              .map(
                (id) => ExpenseSplit(
                  memberId: id,
                  amount: _readAmount(_manualControllers[id]?.text ?? ''),
                ),
              )
              .toList();
    final validation = _validator.validate(
      group: _group,
      amount: amount,
      payerMemberId: _payerMemberId,
      participantIds: participantIds,
      splits: splits,
    );
    if (validation != null) {
      final message = switch (validation) {
        GroupExpenseValidationError.minMembers =>
          context.l10n.validationMinMembers(2),
        GroupExpenseValidationError.amountPositive =>
          context.l10n.validationAmountPositive,
        GroupExpenseValidationError.selectPayer =>
          context.l10n.validationSelectPayer,
        GroupExpenseValidationError.selectParticipant =>
          context.l10n.validationSelectParticipant,
        GroupExpenseValidationError.invalidParticipants =>
          context.l10n.validationInvalidParticipants,
        GroupExpenseValidationError.splitCountMismatch =>
          context.l10n.validationSplitCountMismatch,
        GroupExpenseValidationError.negativeSplit =>
          context.l10n.validationNegativeSplit,
        GroupExpenseValidationError.splitMismatch =>
          context.l10n.validationSplitMismatch(
            splits
                .fold<double>(0, (sum, split) => sum + split.amount)
                .toStringAsFixed(0),
            amount.toStringAsFixed(0),
          ),
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .saveExpense(
            expenseId: widget.args.expense?.id,
            groupId: _group.id,
            payerMemberId: _payerMemberId!,
            amount: amount,
            note: _noteController.text,
            date: _date,
            splits: splits,
          );
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userFriendlyMessage(error))));
        setState(() => _saving = false);
      }
    }
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      trailing: Text(value, style: const TextStyle(color: AppTheme.mint)),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.amber)),
    );
  }
}

double _readAmount(String text) {
  return double.tryParse(text.trim().replaceAll('.', '').replaceAll(',', '')) ??
      0;
}
