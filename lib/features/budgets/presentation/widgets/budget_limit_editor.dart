import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
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
    var amount = category.limitAmount > 0 ? category.limitAmount : 1000000.0;
    var warningRatio = category.warningRatio.clamp(0.5, 1).toDouble();
    var warningsEnabled = warningRatio < 1.0;
    final colors = context.moniaryColors;
    final maxAmount = _sliderMax(amount);
    final presets = _presetsFor(amount);

    final draft = await showModalBottomSheet<_BudgetLimitDraft>(
      context: context,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.background.withValues(alpha: 0.98),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void setAmount(double value) {
              setState(() {
                amount = value.clamp(0, maxAmount).roundToDouble();
              });
            }

            final percent = amount <= 0
                ? 0
                : ((category.spentAmount / amount) * 100).round();
            final status = category.spentAmount > amount
                ? context.l10n.budgetOverLimitShort
                : percent >= 90
                ? context.l10n.budgetNearLimitShort
                : context.l10n.budgetNearLimit;

            return _BudgetLimitSheet(
              category: category,
              amount: amount,
              maxAmount: maxAmount,
              presets: presets,
              warningRatio: warningRatio,
              warningsEnabled: warningsEnabled,
              usedPercent: percent,
              status: status,
              onAmountChanged: setAmount,
              onPresetTap: setAmount,
              onWarningChanged: (enabled) {
                setState(() {
                  warningsEnabled = enabled;
                  warningRatio = enabled ? 0.9 : 1.0;
                });
              },
              onSave: () {
                Navigator.pop(
                  context,
                  _BudgetLimitDraft(
                    amount: amount,
                    warningRatio: warningsEnabled ? warningRatio : 1.0,
                  ),
                );
              },
              onRemove: null,
            );
          },
        );
      },
    );
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

  static double _sliderMax(double amount) {
    if (amount <= 300000) return 500000;
    if (amount <= 3000000) return 5000000;
    return 10000000;
  }

  static List<double> _presetsFor(double amount) {
    if (amount <= 300000) return const [150000, 220000, 300000];
    return const [1500000, 2200000, 3000000];
  }
}

class _BudgetLimitSheet extends StatelessWidget {
  const _BudgetLimitSheet({
    required this.category,
    required this.amount,
    required this.maxAmount,
    required this.presets,
    required this.warningRatio,
    required this.warningsEnabled,
    required this.usedPercent,
    required this.status,
    required this.onAmountChanged,
    required this.onPresetTap,
    required this.onWarningChanged,
    required this.onSave,
    required this.onRemove,
  });

  final CategoryBudget category;
  final double amount;
  final double maxAmount;
  final List<double> presets;
  final double warningRatio;
  final bool warningsEnabled;
  final int usedPercent;
  final String status;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<double> onPresetTap;
  final ValueChanged<bool> onWarningChanged;
  final VoidCallback onSave;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = _budgetAccent(category, colors);
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(top: 96, bottom: keyboardBottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.backgroundSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 10, 30, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.68),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.budgetLimitTitleForCategory(
                              category.categoryName,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.moniaryTypography.displaySmall
                                .copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  height: 1.1,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _formatLimitAmount(context, amount),
                      textAlign: TextAlign.center,
                      style: context.moniaryTypography.displayLarge.copyWith(
                        color: colors.textPrimary,
                        fontSize: 43,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      context.l10n.budgetUsedWarningLine(
                        formatVnd(category.spentAmount),
                        usedPercent,
                        status,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        color: accent,
                        fontSize: 9.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 7,
                        activeTrackColor: accent,
                        inactiveTrackColor: colors.outline.withValues(
                          alpha: 0.55,
                        ),
                        thumbColor: colors.surfaceRaised,
                        overlayColor: accent.withValues(alpha: 0.12),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 17,
                        ),
                      ),
                      child: Slider(
                        value: amount.clamp(0, maxAmount),
                        min: 0,
                        max: maxAmount,
                        onChanged: onAmountChanged,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScaleLabel(label: '0'),
                          _ScaleLabel(label: formatVnd(maxAmount)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: presets.map((preset) {
                        final selected = (amount - preset).abs() < 1;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: preset == presets.last ? 0 : 8,
                            ),
                            child: _PresetButton(
                              amount: preset,
                              selected: selected,
                              accent: accent,
                              onTap: () => onPresetTap(preset),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 19),
                    Divider(color: colors.outline.withValues(alpha: 0.72)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 17,
                          color: colors.textDim,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.budgetAlertAtPercent(
                              (warningRatio * 100).round(),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Switch(
                          value: warningsEnabled,
                          activeThumbColor: AppTheme.surfaceRaised,
                          activeTrackColor: AppTheme.forest,
                          inactiveThumbColor: colors.surfaceRaised,
                          inactiveTrackColor: colors.outline,
                          onChanged: onWarningChanged,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.textPrimary,
                          foregroundColor: colors.surfaceRaised,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(context.l10n.budgetSaveLimit),
                      ),
                    ),
                    if (onRemove != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onRemove,
                          child: Text(
                            context.l10n.budgetRemoveLimit,
                            style: TextStyle(
                              color: colors.danger,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.moniaryTypography.metadata.copyWith(
        color: context.moniaryColors.textDim,
        fontSize: 7.6,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.amount,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final double amount;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : _controlFill(colors),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(
          color: selected ? accent : _controlBorder(colors),
          width: 1.1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 38,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatVnd(amount),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? accent : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetLimitDraft {
  const _BudgetLimitDraft({required this.amount, required this.warningRatio});

  final double amount;
  final double warningRatio;
}

String _formatLimitAmount(BuildContext context, double amount) {
  return formatMoney(amount);
}

Color _budgetAccent(CategoryBudget category, MoniaryColors colors) {
  final key = '${category.categoryId} ${category.categoryName}'.toLowerCase();
  if (key.contains('food') || key.contains('ăn') || key.contains('uong')) {
    return AppTheme.terracotta;
  }
  if (key.contains('shopping') || key.contains('mua')) {
    return AppTheme.sage;
  }
  if (key.contains('transport') ||
      key.contains('đi') ||
      key.contains('di chuyển')) {
    return AppTheme.slate;
  }
  return Color.lerp(
    AppColor.fromHex(category.categoryColor, fallback: colors.primary),
    AppTheme.taupe,
    0.62,
  )!;
}

Color _controlFill(MoniaryColors colors) {
  return Color.lerp(colors.backgroundSoft, colors.textPrimary, 0.025)!;
}

Color _controlBorder(MoniaryColors colors) {
  return Color.lerp(colors.outline, colors.textPrimary, 0.08)!;
}
