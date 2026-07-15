import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/confirm_action_dialog.dart';
import '../../calendar/application/month/calendar_month_provider.dart';
import '../../categories/application/categories_controller.dart';
import '../../categories/domain/models/category.dart';
import '../../statistics/presentation/statistics_view.dart';
import '../../transactions/application/queries/transaction_queries.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/domain/models/wallet.dart';
import '../application/recurring_controller.dart';
import '../application/recurring_materialization_service.dart';
import '../domain/models/recurring_transaction.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  static const routePath = '/recurring-transactions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(recurringControllerProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.recurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.recurringAdd),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(recurringControllerProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _Message(
              icon: Icons.autorenew_outlined,
              message: context.l10n.recurringEmpty,
            );
          }
          return RefreshIndicator(
            color: colors.primary,
            onRefresh: () =>
                ref.read(recurringControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _RecurringCard(
                item: items[index],
                onEdit: () => _openForm(context, item: items[index]),
                onDelete: () => _confirmDelete(context, ref, items[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {RecurringTransaction? item}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringForm(item: item),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransaction item,
  ) async {
    final notifier = ref.read(recurringControllerProvider.notifier);
    var generatedCount = 0;
    try {
      generatedCount = await notifier.generatedTransactionCount(item.id);
    } catch (_) {
      generatedCount = 0;
    }
    if (!context.mounted) return;

    // deleteGenerated: null = cancelled, false = keep transactions,
    // true = also delete generated transactions.
    bool? deleteGenerated;
    if (generatedCount > 0) {
      deleteGenerated = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ConfirmActionDialog<bool>(
          icon: Icons.delete_outline_rounded,
          iconColor: dialogContext.moniaryColors.danger,
          title: dialogContext.l10n.recurringDeleteTitle,
          message: dialogContext.l10n.recurringDeleteGeneratedMessage(
            generatedCount,
          ),
          actions: [
            ConfirmAction(
              dialogContext.l10n.recurringDeleteKeepTx,
              false,
              style: ConfirmActionStyle.neutral,
            ),
            ConfirmAction(
              dialogContext.l10n.recurringDeleteRemoveTx,
              true,
              style: ConfirmActionStyle.danger,
            ),
          ],
        ),
      );
      if (deleteGenerated == null || !context.mounted) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => ConfirmActionDialog<bool>(
          icon: Icons.delete_outline_rounded,
          iconColor: dialogContext.moniaryColors.danger,
          title: dialogContext.l10n.recurringDeleteTitle,
          message: dialogContext.l10n.recurringDeleteMessage,
          actions: [
            ConfirmAction(
              dialogContext.l10n.commonDelete,
              true,
              style: ConfirmActionStyle.danger,
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      deleteGenerated = false;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await notifier.deleteRecurring(
        item.id,
        deleteGeneratedTransactions: deleteGenerated,
      );
      if (deleteGenerated) {
        // Transactions were removed — refresh the views that show them.
        ref.invalidate(calendarMonthProvider);
        ref.invalidate(transactionsForDayProvider);
        ref.invalidate(statisticsMonthProvider);
        ref.invalidate(transactionSearchProvider);
      }
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransaction item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final signColor = item.isIncome ? colors.success : colors.danger;

    return Opacity(
      opacity: item.isActive ? 1 : 0.55,
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          leading: CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Icon(Icons.autorenew, color: colors.primary),
          ),
          title: Text(
            item.note?.trim().isNotEmpty == true
                ? item.note!.trim()
                : item.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${_frequencyLabel(context, item)} · '
              '${context.l10n.recurringNextRunLabel}: '
              '${DateFormat('dd/MM/yyyy').format(item.nextRunDate)}'
              '${item.isActive ? '' : ' · ${context.l10n.recurringPaused}'}',
              style: TextStyle(color: colors.textDim, fontSize: 12),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.isIncome ? '+' : '-'}${ref.formatAmount(item.amount)}',
                style: TextStyle(color: signColor, fontWeight: FontWeight.w700),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
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
          onTap: onEdit,
        ),
      ),
    );
  }
}

String _frequencyLabel(BuildContext context, RecurringTransaction item) {
  final unit = switch (item.frequency) {
    RecurringFrequency.daily => context.l10n.recurringDaily,
    RecurringFrequency.weekly => context.l10n.recurringWeekly,
    RecurringFrequency.monthly => context.l10n.recurringMonthly,
    RecurringFrequency.yearly => context.l10n.recurringYearly,
  };
  if (item.interval <= 1) return unit;
  return context.l10n.recurringEvery(item.interval, unit);
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.item});

  final RecurringTransaction? item;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _interval;
  late TransactionType _type;
  late RecurringFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _autoPost;
  late bool _isActive;
  String? _walletId;
  String? _categoryId;
  bool _submitting = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _amount = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(0) : '',
    );
    _note = TextEditingController(text: item?.note ?? '');
    _interval = TextEditingController(text: (item?.interval ?? 1).toString());
    _type = item?.type ?? TransactionType.expense;
    _frequency = item?.frequency ?? RecurringFrequency.monthly;
    _startDate = item?.startDate ?? DateTime.now();
    _endDate = item?.endDate;
    _autoPost = item?.autoPost ?? false;
    _isActive = item?.isActive ?? true;
    _walletId = item?.walletId;
    _categoryId = item?.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: walletsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFriendlyMessage(context, error)),
          ),
          data: (wallets) => categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(userFriendlyMessage(context, error)),
            ),
            data: (categories) => _buildForm(context, wallets, categories),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Wallet> wallets,
    List<Category> allCategories,
  ) {
    final activeWallets = wallets.where((w) => w.isActive).toList();
    final categories = allCategories
        .where((c) => c.isActive && c.type == _type)
        .toList();

    if (activeWallets.isEmpty) {
      return _sheetMessage(context, context.l10n.recurringNoWallets);
    }
    if (categories.isEmpty) {
      return _sheetMessage(context, context.l10n.recurringNoCategories);
    }

    // Keep selections valid against the available options.
    if (_walletId == null || !activeWallets.any((w) => w.id == _walletId)) {
      _walletId = activeWallets.first.id;
    }
    if (_categoryId == null || !categories.any((c) => c.id == _categoryId)) {
      _categoryId = categories.first.id;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editing ? context.l10n.recurringEdit : context.l10n.recurringAdd,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        SegmentedButton<TransactionType>(
          segments: [
            ButtonSegment(
              value: TransactionType.expense,
              label: Text(context.l10n.recurringExpense),
            ),
            ButtonSegment(
              value: TransactionType.income,
              label: Text(context.l10n.recurringIncome),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (selection) => setState(() {
            _type = selection.first;
            _categoryId = null; // reset — categories are type-scoped
          }),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: context.l10n.recurringAmount,
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _walletId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.recurringWallet,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          items: activeWallets
              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
              .toList(),
          onChanged: (value) => setState(() => _walletId = value),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _categoryId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.recurringCategory,
            prefixIcon: const Icon(Icons.category_outlined),
          ),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: (value) => setState(() => _categoryId = value),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<RecurringFrequency>(
                initialValue: _frequency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFrequency,
                ),
                items: [
                  DropdownMenuItem(
                    value: RecurringFrequency.daily,
                    child: Text(context.l10n.recurringDaily),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.weekly,
                    child: Text(context.l10n.recurringWeekly),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.monthly,
                    child: Text(context.l10n.recurringMonthly),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.yearly,
                    child: Text(context.l10n.recurringYearly),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _frequency = value ?? RecurringFrequency.monthly,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _interval,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.recurringInterval,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _DateTile(
          label: context.l10n.recurringStartDate,
          value: _startDate,
          onPick: (picked) => setState(() {
            _startDate = picked;
            if (_endDate != null && _endDate!.isBefore(picked)) {
              _endDate = null;
            }
          }),
        ),
        _DateTile(
          label: context.l10n.recurringEndDate,
          value: _endDate,
          firstDate: _startDate,
          optional: true,
          placeholder: context.l10n.recurringNoEndDate,
          onPick: (picked) => setState(() => _endDate = picked),
          onClear: () => setState(() => _endDate = null),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _note,
          decoration: InputDecoration(
            labelText: context.l10n.recurringNote,
            prefixIcon: const Icon(Icons.notes_outlined),
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _autoPost,
          onChanged: (value) => setState(() => _autoPost = value),
          title: Text(context.l10n.recurringAutoPost),
          subtitle: Text(context.l10n.recurringAutoPostHelp),
        ),
        if (_editing)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: Text(context.l10n.recurringActive),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting ? context.l10n.commonSaving : context.l10n.commonSave,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetMessage(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  Future<bool> _confirmRegenerate(BuildContext context, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmActionDialog<bool>(
        icon: Icons.autorenew,
        title: dialogContext.l10n.recurringApplyTitle,
        message: dialogContext.l10n.recurringApplyMessage(count),
        actions: [ConfirmAction(dialogContext.l10n.recurringApplyDelete, true)],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final interval = int.tryParse(_interval.text.trim()) ?? 1;

    if (amount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.recurringAmountRequired)),
      );
      return;
    }
    if (_walletId == null || _categoryId == null) return;

    setState(() => _submitting = true);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final safeInterval = interval < 1 ? 1 : interval;

    try {
      final notifier = ref.read(recurringControllerProvider.notifier);
      var transactionsTouched = false;
      if (_editing) {
        final id = widget.item!.id;
        var applyMode = RecurringApplyMode.futureOnly;
        var generatedCount = 0;
        try {
          generatedCount = await notifier.generatedTransactionCount(id);
        } catch (_) {
          generatedCount = 0;
        }
        if (!mounted) return;
        if (generatedCount > 0) {
          final confirmed = await _confirmRegenerate(context, generatedCount);
          if (!confirmed) {
            setState(() => _submitting = false);
            return;
          }
          applyMode = RecurringApplyMode.deleteAndRegenerate;
        }
        transactionsTouched = applyMode != RecurringApplyMode.futureOnly;
        await notifier.updateRecurring(
          id: id,
          amount: amount,
          type: _type,
          walletId: _walletId!,
          categoryId: _categoryId!,
          frequency: _frequency,
          interval: safeInterval,
          startDate: _startDate,
          nextRunDate: _startDate,
          isActive: _isActive,
          endDate: _endDate,
          note: note,
          autoPost: _autoPost,
          applyMode: applyMode,
        );
      } else {
        await notifier.createRecurring(
          amount: amount,
          type: _type,
          walletId: _walletId!,
          categoryId: _categoryId!,
          frequency: _frequency,
          interval: safeInterval,
          startDate: _startDate,
          nextRunDate: _startDate,
          endDate: _endDate,
          note: note,
          autoPost: _autoPost,
        );
      }
      // A rule saved with auto-post and a due date should post immediately,
      // not wait for the next launch.
      if (_autoPost) {
        final posted = await ref
            .read(recurringMaterializationServiceProvider)
            .run();
        if (posted > 0) transactionsTouched = true;
      }
      if (transactionsTouched) {
        await notifier.refresh();
        ref.invalidate(calendarMonthProvider);
        ref.invalidate(transactionsForDayProvider);
        ref.invalidate(statisticsMonthProvider);
        ref.invalidate(transactionSearchProvider);
      }
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.recurringSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _submitting = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onPick,
    this.firstDate,
    this.optional = false,
    this.placeholder,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final DateTime? firstDate;
  final bool optional;
  final String? placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? DateFormat('dd/MM/yyyy').format(value!)
        : (placeholder ?? '');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      subtitle: Text(display),
      trailing: optional && value != null && onClear != null
          ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
          : const Icon(Icons.chevron_right),
      onTap: () async {
        final now = DateTime.now();
        final base = firstDate ?? DateTime(now.year - 1);
        final initial = value ?? (base.isAfter(now) ? base : now);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: base,
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.icon, this.onRetry});

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 46, color: context.moniaryColors.textDim),
            const SizedBox(height: 12),
          ],
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
    ),
  );
}
