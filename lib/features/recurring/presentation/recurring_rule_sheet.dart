import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../categories/application/categories_controller.dart';
import '../../categories/domain/models/category.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/domain/models/wallet.dart';
import '../application/recurring_controller.dart';
import '../domain/models/recurring_rule.dart';

/// Localized label for a recurrence frequency, suffixed with the interval when
/// it repeats every N > 1 periods.
String recurringScheduleLabel(BuildContext context, RecurringRule rule) {
  final base = frequencyLabel(context, rule.frequency);
  return rule.interval > 1 ? '$base ×${rule.interval}' : base;
}

String frequencyLabel(BuildContext context, RecurrenceFrequency frequency) {
  return switch (frequency) {
    RecurrenceFrequency.daily => context.l10n.recurringFrequencyDaily,
    RecurrenceFrequency.weekly => context.l10n.recurringFrequencyWeekly,
    RecurrenceFrequency.monthly => context.l10n.recurringFrequencyMonthly,
    RecurrenceFrequency.yearly => context.l10n.recurringFrequencyYearly,
  };
}

/// Opens the create/edit sheet. Returns `true` when a rule was saved or
/// deleted, so callers can refresh reminders.
Future<bool?> showRecurringRuleSheet(
  BuildContext context, {
  RecurringRule? initial,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RecurringRuleSheet(initial: initial),
  );
}

class _RecurringRuleSheet extends ConsumerStatefulWidget {
  const _RecurringRuleSheet({this.initial});

  final RecurringRule? initial;

  @override
  ConsumerState<_RecurringRuleSheet> createState() =>
      _RecurringRuleSheetState();
}

class _RecurringRuleSheetState extends ConsumerState<_RecurringRuleSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late RecurrenceFrequency _frequency;
  late int _interval;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _autoPost;
  String? _walletId;
  String? _categoryId;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final rule = widget.initial;
    _amountController = TextEditingController(
      text: rule == null ? '' : rule.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: rule?.note ?? '');
    _type = rule?.type ?? TransactionType.expense;
    _frequency = rule?.frequency ?? RecurrenceFrequency.monthly;
    _interval = rule?.interval ?? 1;
    _startDate = rule?.startDate ?? dateOnly(DateTime.now());
    _endDate = rule?.endDate;
    _autoPost = rule?.autoPost ?? false;
    _walletId = rule?.walletId;
    _categoryId = rule?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setDefaults();
    });
  }

  void _setDefaults() {
    final wallets = _activeWallets();
    final categories = _categoriesForType();
    var changed = false;
    if (_walletId == null && wallets.isNotEmpty) {
      _walletId = wallets
          .firstWhere((w) => w.isDefault, orElse: () => wallets.first)
          .id;
      changed = true;
    }
    if (categories.isNotEmpty && !categories.any((c) => c.id == _categoryId)) {
      _categoryId = categories.first.id;
      changed = true;
    }
    if (changed) setState(() {});
  }

  List<Wallet> _activeWallets() {
    return ref
            .read(walletsControllerProvider)
            .asData
            ?.value
            .where((w) => w.isActive)
            .toList() ??
        const [];
  }

  List<Category> _categoriesForType() {
    return ref
            .read(categoriesControllerProvider)
            .asData
            ?.value
            .where((c) => c.isActive && c.type == _type)
            .toList() ??
        const [];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final wallets = _activeWallets();
    final categories = _categoriesForType();
    final saving = ref.watch(recurringControllerProvider).isLoading;
    final canSubmit = wallets.isNotEmpty && categories.isNotEmpty && !saving;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isEditing
                    ? context.l10n.recurringEditTitle
                    : context.l10n.recurringAddTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  _Chip(
                    label: context.l10n.categoryExpense,
                    selected: _type == TransactionType.expense,
                    onTap: () => _setType(TransactionType.expense),
                  ),
                  _Chip(
                    label: context.l10n.categoryIncome,
                    selected: _type == TransactionType.income,
                    onTap: () => _setType(TransactionType.income),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.transactionAmount,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                isExpanded: true,
                items: [
                  for (final wallet in wallets)
                    DropdownMenuItem(
                      value: wallet.id,
                      child: Text(wallet.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: wallets.isEmpty
                    ? null
                    : (value) => setState(() => _walletId = value),
                decoration: InputDecoration(
                  labelText: context.l10n.transactionWallet,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.id == _categoryId)
                    ? _categoryId
                    : null,
                isExpanded: true,
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: categories.isEmpty
                    ? null
                    : (value) => setState(() => _categoryId = value),
                decoration: InputDecoration(
                  labelText: context.l10n.transactionCategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RecurrenceFrequency>(
                      initialValue: _frequency,
                      isExpanded: true,
                      items: [
                        for (final frequency in RecurrenceFrequency.values)
                          DropdownMenuItem(
                            value: frequency,
                            child: Text(
                              frequencyLabel(context, frequency),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _frequency = value ?? _frequency),
                      decoration: InputDecoration(
                        labelText: context.l10n.recurringFrequencyLabel,
                        prefixIcon: const Icon(Icons.repeat_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _IntervalStepper(
                    value: _interval,
                    onChanged: (value) => setState(() => _interval = value),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DateTile(
                label: context.l10n.recurringStartDateLabel,
                value: DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(_startDate),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 10),
              _DateTile(
                label: context.l10n.recurringEndDateLabel,
                value: _endDate == null
                    ? context.l10n.recurringNoEndDate
                    : DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(_endDate!),
                onTap: _pickEndDate,
                onClear: _endDate == null
                    ? null
                    : () => setState(() => _endDate = null),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outline),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoPost,
                  onChanged: (value) => setState(() => _autoPost = value),
                  activeThumbColor: AppTheme.mint,
                  title: Text(context.l10n.recurringAutoPostLabel),
                  subtitle: Text(
                    context.l10n.recurringAutoPostHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.transactionNote,
                ),
              ),
              if (wallets.isEmpty || categories.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  wallets.isEmpty
                      ? context.l10n.walletNeedOneActive
                      : context.l10n.categoryNeedOneActive,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.amber),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: Text(
                  saving ? context.l10n.commonSaving : context.l10n.commonSave,
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: saving ? null : _confirmDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                  label: Text(
                    context.l10n.commonDelete,
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      _categoryId = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setDefaults();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = dateOnly(picked));
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = dateOnly(picked));
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transactionAmountInvalid)),
      );
      return;
    }
    if (_walletId == null || _categoryId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transactionSelectWalletCategory)),
      );
      return;
    }

    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final controller = ref.read(recurringControllerProvider.notifier);

    try {
      if (_isEditing) {
        final rule = widget.initial!;
        final nextRun = _startDate.isAfter(rule.nextRunDate)
            ? _startDate
            : rule.nextRunDate;
        await controller.updateRule(
          ruleId: rule.id,
          amount: amount,
          type: _type,
          walletId: _walletId!,
          categoryId: _categoryId!,
          frequency: _frequency,
          interval: _interval,
          startDate: _startDate,
          nextRunDate: nextRun,
          endDate: _endDate,
          autoPost: _autoPost,
          note: note,
        );
      } else {
        await controller.createRule(
          amount: amount,
          type: _type,
          walletId: _walletId!,
          categoryId: _categoryId!,
          frequency: _frequency,
          interval: _interval,
          startDate: _startDate,
          endDate: _endDate,
          autoPost: _autoPost,
          note: note,
        );
      }
      if (mounted) context.pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recurringDeleteConfirmTitle),
        content: Text(l10n.recurringDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(recurringControllerProvider.notifier)
          .deleteRule(widget.initial!.id);
      if (mounted) context.pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 60 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                  ),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
              )
            else
              const Icon(Icons.chevron_right_outlined),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.mint : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.mint : AppTheme.outline,
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
