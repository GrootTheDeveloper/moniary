import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupBudgetScreen extends ConsumerWidget {
  const GroupBudgetScreen({required this.groupId, super.key});

  static const routePath = '/groups/budget';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(groupBudgetProvider(groupId));
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupBudgetTitle),
        actions: detailAsync.hasValue &&
                detailAsync.value!.currentUserRole.index <= 1 &&
                budgetAsync.hasValue
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditSheet(context, ref, budgetAsync.value),
                  tooltip: context.l10n.commonEdit,
                ),
              ]
            : null,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFriendlyMessage(context, error), textAlign: TextAlign.center),
          ),
        ),
        data: (detail) => budgetAsync.when(
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
        data: (budget) {
          if (budget == null || !budget.hasLimit) {
            return ListView(
              children: [
                SizedBox(
                  height: 360,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          size: 44,
                          color: colors.textDim,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.groupBudgetNotSet,
                          style: TextStyle(color: colors.textDim),
                          textAlign: TextAlign.center,
                        ),
                        if (detail.currentUserRole.index <= 1) ...[
                          const SizedBox(height: 24),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _showEditSheet(context, ref, budget),
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.groupBudgetSet),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.groupBudgetMonthlyLimit,
                        style: TextStyle(
                          color: colors.textDim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatMoney(budget.monthlyLimit),
                        style: context.moniaryTypography.displaySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: colors.textDim),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.groupBudgetWarningThreshold,
                              style: TextStyle(
                                color: colors.textDim,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${budget.warningThresholdPercent}%',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    GroupBudget? current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _EditBudgetSheet(
        groupId: groupId,
        current: current,
      ),
    );
  }
}

class _EditBudgetSheet extends ConsumerStatefulWidget {
  const _EditBudgetSheet({required this.groupId, this.current});

  final String groupId;
  final GroupBudget? current;

  @override
  ConsumerState<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<_EditBudgetSheet> {
  late final TextEditingController _limitController;
  late int _warningPercent;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _limitController =
        TextEditingController(text: (widget.current?.monthlyLimit ?? 0).toString());
    _warningPercent = widget.current?.warningThresholdPercent ?? 80;
  }

  @override
  void dispose() {
    _limitController.dispose();
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
              context.l10n.groupBudgetEditTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              decoration: InputDecoration(
                labelText: context.l10n.groupBudgetMonthlyLimit,
                prefixIcon: const Icon(Icons.savings_outlined),
                suffixText: '  ',
              ),
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.groupBudgetWarningThreshold,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '$_warningPercent%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _warningPercent.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (value) => setState(() => _warningPercent = value.toInt()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? context.l10n.commonSaving
                    : context.l10n.commonSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final limit = int.tryParse(_limitController.text.trim()) ?? 0;

    if (limit < 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.groupBudgetInvalidAmount),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(groupActionControllerProvider.notifier).upsertGroupBudget(
            groupId: widget.groupId,
            monthlyLimit: limit,
            warningThresholdPercent: _warningPercent,
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupBudgetSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}
