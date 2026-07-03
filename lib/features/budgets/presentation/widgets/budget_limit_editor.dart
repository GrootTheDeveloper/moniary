import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../application/budget_controller.dart';
import '../../domain/monthly_budget.dart';

class BudgetLimitEditor {
  const BudgetLimitEditor._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime month,
    required CategoryBudget category,
  }) async {
    final controller = TextEditingController(
      text: category.limitAmount > 0
          ? category.limitAmount.round().toString()
          : '',
    );
    var warningRatio = category.warningRatio.clamp(0.5, 1).toDouble();
    final presets = <double>[500000, 1000000, 2000000, 5000000];

    final draft = await showModalBottomSheet<_BudgetLimitDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.moniaryColors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.budgetEditLimit,
                style: context.moniaryTypography.metadataStrong,
              ),
              const SizedBox(height: 4),
              Text(
                category.categoryName,
                style: context.moniaryTypography.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(context.l10n.budgetLimitHelper),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.l10n.budgetMonthlyLimit,
                  suffixText: context.l10n.transactionAmountSuffix,
                ),
              ),
              const SizedBox(height: 14),
              MoniarySectionLabel(context.l10n.budgetQuickPresets),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in presets)
                    ActionChip(
                      label: Text(formatVnd(preset)),
                      onPressed: () {
                        controller.text = preset.round().toString();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.budgetWarningThreshold,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${(warningRatio * 100).round()}%',
                    style: context.moniaryTypography.metadataStrong,
                  ),
                ],
              ),
              Slider(
                value: warningRatio,
                min: 0.5,
                max: 1,
                divisions: 10,
                label: '${(warningRatio * 100).round()}%',
                onChanged: (value) => setState(() => warningRatio = value),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {
                  final value = double.tryParse(controller.text) ?? 0;
                  Navigator.pop(
                    context,
                    _BudgetLimitDraft(
                      amount: value,
                      warningRatio: warningRatio,
                    ),
                  );
                },
                child: Text(context.l10n.commonSave),
              ),
              if (category.limitAmount > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _BudgetLimitDraft(amount: 0, warningRatio: warningRatio),
                  ),
                  child: Text(
                    context.l10n.budgetRemoveLimit,
                    style: TextStyle(color: context.moniaryColors.danger),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (draft == null || !context.mounted) return;

    try {
      await ref
          .read(budgetActionControllerProvider.notifier)
          .setLimit(
            month: month,
            categoryId: category.categoryId,
            amount: draft.amount,
            warningRatio: draft.warningRatio,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _BudgetLimitDraft {
  const _BudgetLimitDraft({required this.amount, required this.warningRatio});

  final double amount;
  final double warningRatio;
}
