import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupRecurringTransactionsScreen extends ConsumerWidget {
  const GroupRecurringTransactionsScreen({required this.groupId, super.key});

  static const routePath = '/groups/recurring';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(
      groupRecurringTransactionsProvider(groupId),
    );
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupRecurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.groupRecurringAdd),
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              userFriendlyMessage(context, error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          return RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.backgroundSoft,
            onRefresh: () async =>
                ref.invalidate(groupRecurringTransactionsProvider(groupId)),
            child: items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 360,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_repeat_outlined,
                                size: 44,
                                color: colors.textDim,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.groupRecurringEmpty,
                                style: TextStyle(color: colors.textDim),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _RecurringTile(
                      groupId: groupId,
                      item: items[index],
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _showForm(
    BuildContext context,
    WidgetRef ref, {
    GroupRecurringTransaction? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RecurringFormSheet(
        groupId: groupId,
        existing: existing,
      ),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  const _RecurringTile({required this.groupId, required this.item});

  final String groupId;
  final GroupRecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final dimmed = !item.isActive;

    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceRaised.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.outline),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (sheetContext) => _RecurringFormSheet(
              groupId: groupId,
              existing: item,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_frequencyLabel(context, item.frequency)} · '
              '${context.l10n.groupRecurringNextRun}: '
              '${DateFormat.yMMMd().format(item.nextRunAt)}',
              style: TextStyle(color: colors.textDim, fontSize: 12),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(item.amount),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!item.isActive)
                Text(
                  context.l10n.groupRecurringInactive,
                  style: TextStyle(color: colors.textDim, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _frequencyLabel(BuildContext context, String frequency) {
  return switch (frequency) {
    'weekly' => context.l10n.groupRecurringWeekly,
    _ => context.l10n.groupRecurringMonthly,
  };
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({required this.groupId, this.existing});

  final String groupId;
  final GroupRecurringTransaction? existing;

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _frequency;
  late DateTime _nextRunAt;
  late int _notifyDaysBefore;
  bool _isSubmitting = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _frequency = e?.frequency ?? 'monthly';
    _nextRunAt = e?.nextRunAt ?? DateTime.now().add(const Duration(days: 30));
    _notifyDaysBefore = e?.notifyDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing
                  ? context.l10n.groupRecurringEditTitle
                  : context.l10n.groupRecurringAdd,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.l10n.groupRecurringName,
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(
                labelText: context.l10n.groupRecurringAmount,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.groupRecurringFrequency,
                prefixIcon: const Icon(Icons.repeat_outlined),
              ),
              items: [
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text(context.l10n.groupRecurringWeekly),
                ),
                DropdownMenuItem(
                  value: 'monthly',
                  child: Text(context.l10n.groupRecurringMonthly),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(context.l10n.groupRecurringNextRun),
              subtitle: Text(DateFormat.yMMMd().format(_nextRunAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const SizedBox(height: 6),
            Text(
              '${context.l10n.groupRecurringNotifyDays}: $_notifyDaysBefore',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _notifyDaysBefore.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '$_notifyDaysBefore',
              onChanged: (value) =>
                  setState(() => _notifyDaysBefore = value.toInt()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? context.l10n.commonSaving
                    : context.l10n.commonSave,
              ),
            ),
            if (_editing && widget.existing!.isActive) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _deactivate,
                icon: const Icon(Icons.pause_circle_outline),
                label: Text(context.l10n.groupRecurringDeactivate),
              ),
            ],
            if (_editing && !widget.existing!.isActive) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _reactivate,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(context.l10n.groupRecurringReactivate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRunAt.isBefore(now) ? now : _nextRunAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _nextRunAt = picked);
  }

  Future<void> _submit({bool? overrideActive}) async {
    final messenger = ScaffoldMessenger.of(context);
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupRecurringNameRequired)),
      );
      return;
    }
    if (amount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupRecurringAmountRequired)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(groupActionControllerProvider.notifier);
      if (_editing) {
        await notifier.updateRecurringTransaction(
          id: widget.existing!.id,
          groupId: widget.groupId,
          title: title,
          amount: amount,
          frequency: _frequency,
          nextRunAt: _nextRunAt,
          notifyDaysBefore: _notifyDaysBefore,
          isActive: overrideActive ?? widget.existing!.isActive,
        );
      } else {
        await notifier.createRecurringTransaction(
          groupId: widget.groupId,
          title: title,
          amount: amount,
          frequency: _frequency,
          nextRunAt: _nextRunAt,
          notifyDaysBefore: _notifyDaysBefore,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupRecurringSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deactivate() => _submit(overrideActive: false);

  Future<void> _reactivate() => _submit(overrideActive: true);
}
