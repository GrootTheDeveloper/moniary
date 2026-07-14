import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupBudgetScreen extends ConsumerStatefulWidget {
  const GroupBudgetScreen({required this.groupId, super.key});

  static const routePath = '/group-budget';
  final String groupId;

  @override
  ConsumerState<GroupBudgetScreen> createState() => _GroupBudgetScreenState();
}

class _GroupBudgetScreenState extends ConsumerState<GroupBudgetScreen> {
  final _limitController = TextEditingController();
  int _threshold = 80;
  bool _initialized = false;

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(groupBudgetProvider(widget.groupId));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupBudgetTitle)),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BudgetMessage(
          text: userFriendlyMessage(context, error),
          action: () => ref.invalidate(groupBudgetProvider(widget.groupId)),
        ),
        data: (budget) {
          if (!_initialized) {
            _initialized = true;
            _limitController.text = budget.monthlyLimit.toString();
            _threshold = budget.warningThresholdPercent;
          }
          final role = detailAsync.asData?.value.currentUserRole;
          final canEdit = role == GroupRole.owner || role == GroupRole.admin;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            children: [
              Text(
                context.l10n.groupBudgetSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _limitController,
                enabled: canEdit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.groupBudgetMonthlyLimit,
                  suffixText: context.l10n.groupBudgetCurrencySuffix,
                ),
              ),
              const SizedBox(height: 24),
              Text(context.l10n.groupBudgetWarningThreshold),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _threshold.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: '$_threshold%',
                      onChanged: canEdit
                          ? (value) =>
                                setState(() => _threshold = value.round())
                          : null,
                    ),
                  ),
                  Text('$_threshold%'),
                ],
              ),
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    context.l10n.groupBudgetAdminOnly,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              if (canEdit) ...[
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: ref.watch(groupActionControllerProvider).isLoading
                      ? null
                      : () => _save(),
                  child: Text(context.l10n.commonSave),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final limit = int.tryParse(_limitController.text.trim());
    if (limit == null || limit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupBudgetInvalidLimit)),
      );
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateBudget(
            GroupBudget(
              groupId: widget.groupId,
              monthlyLimit: limit,
              warningThresholdPercent: _threshold,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.commonSaved)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }
}

class _BudgetMessage extends StatelessWidget {
  const _BudgetMessage({required this.text, required this.action});
  final String text;
  final VoidCallback action;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: action,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}
