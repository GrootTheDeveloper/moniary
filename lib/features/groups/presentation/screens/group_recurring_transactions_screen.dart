import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupRecurringTransactionsScreen extends ConsumerWidget {
  const GroupRecurringTransactionsScreen({required this.groupId, super.key});

  static const routePath = '/group-recurring-transactions';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(groupRecurringTransactionsProvider(groupId));
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupRecurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.groupRecurringAdd),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          message: userFriendlyMessage(context, error),
          onRetry: () =>
              ref.invalidate(groupRecurringTransactionsProvider(groupId)),
        ),
        data: (items) => items.isEmpty
            ? _Message(message: context.l10n.groupRecurringEmpty)
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(groupRecurringTransactionsProvider(groupId)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _RecurringCard(
                    item: items[index],
                    onEdit: () => _showForm(context, ref, item: items[index]),
                    onDelete: () => _delete(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    GroupRecurringTransaction? item,
  }) async {
    final result = await showDialog<_RecurringFormValue>(
      context: context,
      builder: (_) => _RecurringForm(item: item),
    );
    if (result == null || !context.mounted) return;
    try {
      final controller = ref.read(groupActionControllerProvider.notifier);
      if (item == null) {
        await controller.createRecurringTransaction(
          groupId: groupId,
          title: result.title,
          amount: result.amount,
          frequency: result.frequency,
          nextRunAt: result.nextRunAt,
          notifyDaysBefore: result.notifyDaysBefore,
          autoPost: result.autoPost,
        );
      } else {
        await controller.updateRecurringTransaction(
          groupId: groupId,
          id: item.id,
          title: result.title,
          amount: result.amount,
          frequency: result.frequency,
          nextRunAt: result.nextRunAt,
          notifyDaysBefore: result.notifyDaysBefore,
          isActive: result.isActive,
          autoPost: result.autoPost,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GroupRecurringTransaction item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupRecurringDeleteTitle),
        content: Text(context.l10n.groupRecurringDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .deleteRecurringTransaction(groupId: groupId, id: item.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final GroupRecurringTransaction item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      leading: CircleAvatar(
        backgroundColor: context.moniaryColors.primary.withValues(alpha: .12),
        child: Icon(Icons.autorenew, color: context.moniaryColors.primary),
      ),
      title: Text(item.title),
      subtitle: Text(
        '${item.amount} • ${item.frequency} • ${DateFormat('dd/MM/yyyy').format(item.nextRunAt.toLocal())}',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(context.l10n.commonEdit)),
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    ),
  );
}

class _RecurringFormValue {
  const _RecurringFormValue({
    required this.title,
    required this.amount,
    required this.frequency,
    required this.nextRunAt,
    required this.notifyDaysBefore,
    required this.isActive,
    required this.autoPost,
  });
  final String title;
  final int amount;
  final String frequency;
  final DateTime nextRunAt;
  final int notifyDaysBefore;
  final bool isActive;
  final bool autoPost;
}

class _RecurringForm extends StatefulWidget {
  const _RecurringForm({this.item});
  final GroupRecurringTransaction? item;

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late DateTime _date;
  late String _frequency;
  late int _notifyDays;
  late bool _active;
  late bool _autoPost;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title);
    _amount = TextEditingController(text: item?.amount.toString());
    _date = item?.nextRunAt.toLocal() ?? DateTime.now();
    _frequency = item?.frequency ?? 'monthly';
    _notifyDays = item?.notifyDaysBefore ?? 1;
    _active = item?.isActive ?? true;
    _autoPost = item?.autoPost ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.item == null
          ? context.l10n.groupRecurringAdd
          : context.l10n.groupRecurringEdit,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: context.l10n.groupRecurringName,
            ),
          ),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.l10n.groupRecurringAmount,
            ),
          ),
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            decoration: InputDecoration(
              labelText: context.l10n.groupRecurringFrequency,
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
            onChanged: (value) =>
                setState(() => _frequency = value ?? 'monthly'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.groupRecurringNextRun),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
                initialDate: _date.isBefore(DateTime.now())
                    ? DateTime.now()
                    : _date,
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          DropdownButtonFormField<int>(
            initialValue: _notifyDays,
            decoration: InputDecoration(
              labelText: context.l10n.groupRecurringNotifyBefore,
            ),
            items: List.generate(
              8,
              (index) => DropdownMenuItem(value: index, child: Text('$index')),
            ),
            onChanged: (value) => setState(() => _notifyDays = value ?? 1),
          ),
          if (widget.item != null)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.groupRecurringActive),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.groupRecurringAutoPost),
            subtitle: Text(context.l10n.groupRecurringAutoPostSubtitle),
            value: _autoPost,
            onChanged: (value) => setState(() => _autoPost = value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
    ],
  );

  void _submit() {
    final title = _title.text.trim();
    final amount = int.tryParse(_amount.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;
    Navigator.pop(
      context,
      _RecurringFormValue(
        title: title,
        amount: amount,
        frequency: _frequency,
        nextRunAt: _date,
        notifyDaysBefore: _notifyDays,
        isActive: _active,
        autoPost: _autoPost,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ],
    ),
  );
}
