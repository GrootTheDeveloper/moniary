import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../application/budget_controller.dart';
import '../domain/monthly_budget.dart';
import 'budget_category_detail_screen.dart';
import 'widgets/budget_limit_editor.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  static const routePath = '/budgets';

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final budgetAsync = ref.watch(monthlyBudgetProvider(_month));
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: budgetAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (error, _) => _BudgetError(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(monthlyBudgetProvider(_month)),
        ),
        data: (budget) => _BudgetBody(
          month: _month,
          budget: budget,
          onRefresh: () async => ref.invalidate(monthlyBudgetProvider(_month)),
          onAdd: () => _showCategoryPicker(budget),
          onTapCategory: (category) => context.push(
            BudgetCategoryDetailScreen.routePath,
            extra: BudgetCategoryDetailArgs(
              month: _month,
              categoryId: category.categoryId,
            ),
          ),
          onEditCategory: _showLimitEditor,
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(MonthlyBudget budget) async {
    final selected = await showModalBottomSheet<CategoryBudget>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(budget: budget),
    );
    if (selected != null && mounted) {
      await _showLimitEditor(selected);
    }
  }

  Future<void> _showLimitEditor(CategoryBudget category) async {
    await BudgetLimitEditor.show(
      context: context,
      ref: ref,
      month: _month,
      category: category,
    );
  }
}

class _BudgetBody extends StatelessWidget {
  const _BudgetBody({
    required this.month,
    required this.budget,
    required this.onRefresh,
    required this.onAdd,
    required this.onTapCategory,
    required this.onEditCategory,
  });

  final DateTime month;
  final MonthlyBudget budget;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<CategoryBudget> onTapCategory;
  final ValueChanged<CategoryBudget> onEditCategory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: RefreshIndicator(
            color: context.moniaryColors.primary,
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 88),
              children: [
                _BudgetTopBar(month: month, onAdd: onAdd),
                const SizedBox(height: 28),
                _BudgetProgressHero(budget: budget),
                const SizedBox(height: 31),
                _BudgetCategoryHeader(onEdit: onAdd),
                const SizedBox(height: 6),
                if (budget.categories.isEmpty)
                  _EmptyBudget(onAdd: onAdd)
                else ...[
                  for (final category in budget.categories)
                    _BudgetCategoryRow(
                      category: category,
                      onTap: () => onTapCategory(category),
                      onEdit: () => onEditCategory(category),
                    ),
                  if (budget.unbudgetedCategories.isNotEmpty)
                    _AddCategoryRow(onTap: onAdd),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetTopBar extends StatelessWidget {
  const _BudgetTopBar({required this.month, required this.onAdd});

  final DateTime month;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      children: [
        _TopIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/statistics');
            }
          },
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                context.l10n.budgetTitle,
                textAlign: TextAlign.center,
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _monthLabel(context, month).toUpperCase(),
                style: context.moniaryTypography.metadata.copyWith(
                  color: colors.textDim,
                  fontSize: 7.5,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        _TopIconButton(
          icon: Icons.edit_outlined,
          tooltip: context.l10n.budgetEditLimit,
          onTap: onAdd,
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _controlFill(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _controlBorder(colors), width: 1.1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: colors.textDim),
          ),
        ),
      ),
    );
  }
}

class _BudgetProgressHero extends StatelessWidget {
  const _BudgetProgressHero({required this.budget});

  final MonthlyBudget budget;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final percent = (budget.progress * 100).round();
    final accent =
        budget.totalLimit > 0 && budget.totalSpent > budget.totalLimit
        ? colors.danger
        : AppTheme.terracotta;

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: budget.totalLimit <= 0 ? 0 : budget.progress,
                  strokeWidth: 13,
                  strokeCap: StrokeCap.round,
                  color: accent,
                  backgroundColor: colors.outline.withValues(alpha: 0.45),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.budgetUsed.toUpperCase(),
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: colors.textDim,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$percent%',
                    style: context.moniaryTypography.displaySmall.copyWith(
                      color: colors.textPrimary,
                      fontSize: 26,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.l10n.budgetSpentOfLimit(
            formatVnd(budget.totalSpent),
            formatVnd(budget.totalLimit),
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textDim,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryHeader extends StatelessWidget {
  const _BudgetCategoryHeader({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.budgetCategoryLimits.toUpperCase(),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textDim,
                  fontSize: 9,
                  letterSpacing: 2.2,
                ),
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.terracotta,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(context.l10n.commonEdit),
            ),
          ],
        ),
        Text(
          context.l10n.budgetEmptyBody,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textDim,
            fontSize: 10.5,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({
    required this.category,
    required this.onTap,
    required this.onEdit,
  });

  final CategoryBudget category;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final baseColor = _budgetAccent(category);
    final accent = category.isOverLimit
        ? colors.danger
        : category.isNearLimit
        ? AppTheme.terracotta
        : baseColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              _MiniProgressRing(
                value: category.progress,
                color: accent,
                overLimit: category.isOverLimit,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${formatVnd(category.spentAmount)} / ${formatVnd(category.limitAmount)}',
                          ),
                          if (category.isNearLimit || category.isOverLimit)
                            TextSpan(
                              text:
                                  ' · ${category.isOverLimit ? context.l10n.budgetOverLimitShort : context.l10n.budgetNearLimitShort}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        color: accent,
                        fontSize: 8.4,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textDim.withValues(alpha: 0.66),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgressRing extends StatelessWidget {
  const _MiniProgressRing({
    required this.value,
    required this.color,
    required this.overLimit,
  });

  final double value;
  final Color color;
  final bool overLimit;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: overLimit ? 1 : value,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: colors.outline.withValues(alpha: 0.45),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

class _AddCategoryRow extends StatelessWidget {
  const _AddCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              CustomPaint(
                painter: _DashedCirclePainter(color: colors.outline),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: colors.textDim,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.budgetAddCategory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textDim.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.only(top: 38),
      child: Column(
        children: [
          CustomPaint(
            painter: _DashedCirclePainter(color: colors.outline),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.add_rounded, size: 20, color: colors.textDim),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.budgetEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.budgetEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textDim,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAdd,
            child: Text(context.l10n.budgetAddCategory),
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.budget});

  final MonthlyBudget budget;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSoft,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.budgetChooseCategory,
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: budget.unbudgetedCategories.length,
                  itemBuilder: (context, index) {
                    final category = budget.unbudgetedCategories[index];
                    final color = AppColor.fromHex(
                      category.categoryColor,
                      fallback: AppTheme.taupe,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.pop(context, category),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      title: Text(category.categoryName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetError extends StatelessWidget {
  const _BudgetError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final path = Path()..addOval(rect.deflate(1));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 4.5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

String _monthLabel(BuildContext context, DateTime month) {
  final raw = DateFormat.yMMMM(
    Localizations.localeOf(context).toString(),
  ).format(month);
  return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
}

Color _budgetAccent(CategoryBudget category) {
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
    AppColor.fromHex(category.categoryColor, fallback: AppTheme.taupe),
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
