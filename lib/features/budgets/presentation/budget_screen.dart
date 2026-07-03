import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
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
    final budgetAsync = ref.watch(monthlyBudgetProvider(_month));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.budgetTitle)),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BudgetError(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(monthlyBudgetProvider(_month)),
        ),
        data: (budget) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(monthlyBudgetProvider(_month)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
            children: [
              _MonthSelector(
                month: _month,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
              const SizedBox(height: 14),
              _BudgetHero(budget: budget),
              MoniarySectionLabel(
                context.l10n.budgetCategoryLimits,
                trailing: TextButton(
                  onPressed: budget.unbudgetedCategories.isEmpty
                      ? null
                      : () => _showCategoryPicker(budget),
                  child: Text(context.l10n.commonAdd),
                ),
              ),
              if (budget.categories.isEmpty)
                _EmptyBudget(onAdd: () => _showCategoryPicker(budget))
              else
                for (var index = 0; index < budget.categories.length; index++)
                  _BudgetCategoryRow(
                    category: budget.categories[index],
                    showTopDivider: index == 0,
                    onTap: () => context.push(
                      BudgetCategoryDetailScreen.routePath,
                      extra: BudgetCategoryDetailArgs(
                        month: _month,
                        categoryId: budget.categories[index].categoryId,
                      ),
                    ),
                    onEdit: () => _showLimitEditor(budget.categories[index]),
                  ),
              if (budget.unbudgetedCategories.isNotEmpty) ...[
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () => _showCategoryPicker(budget),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.budgetAddCategory),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
    });
  }

  Future<void> _showCategoryPicker(MonthlyBudget budget) async {
    final selected = await showModalBottomSheet<CategoryBudget>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => Padding(
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
                  color: context.moniaryColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.budgetChooseCategory,
              style: context.moniaryTypography.displayMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: budget.unbudgetedCategories.length,
                itemBuilder: (context, index) {
                  final category = budget.unbudgetedCategories[index];
                  return MoniaryHairlineTile(
                    showTopDivider: index == 0,
                    onTap: () => Navigator.pop(context, category),
                    leading: MoniaryDotBadge(
                      color: AppColor.fromHex(
                        category.categoryColor,
                        fallback: AppTheme.sand,
                      ),
                    ),
                    title: Text(category.categoryName),
                    trailing: const Icon(Icons.arrow_forward, size: 18),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final raw = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(month);
    final label = raw.isEmpty
        ? raw
        : '${raw[0].toUpperCase()}${raw.substring(1)}';
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displaySmall,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _BudgetHero extends StatelessWidget {
  const _BudgetHero({required this.budget});

  final MonthlyBudget budget;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final percent = (budget.progress * 100).round();
    final statusColor =
        budget.totalLimit > 0 && budget.totalSpent > budget.totalLimit
        ? colors.danger
        : percent >= 90
        ? colors.warning
        : colors.primary;

    return MoniaryEditorialCard(
      radius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.budgetUsed.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: context.moniaryTypography.displayLarge.copyWith(
              color: statusColor,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 12),
          MoniaryProgressBar(
            value: budget.progress,
            height: 8,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.budgetSpentOfLimit(
              formatVnd(budget.totalSpent),
              formatVnd(budget.totalLimit),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  const _BudgetCategoryRow({
    required this.category,
    required this.showTopDivider,
    required this.onTap,
    required this.onEdit,
  });

  final CategoryBudget category;
  final bool showTopDivider;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = category.isOverLimit
        ? colors.danger
        : category.isNearLimit
        ? colors.warning
        : AppColor.fromHex(category.categoryColor, fallback: colors.primary);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            top: showTopDivider
                ? BorderSide(color: colors.textPrimary.withValues(alpha: 0.12))
                : BorderSide.none,
            bottom: BorderSide(
              color: colors.textPrimary.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MoniaryDotBadge(color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.categoryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.budgetEditLimit,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colors.textDim,
                  ),
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: 10),
            MoniaryProgressBar(
              value: category.progress,
              color: accent,
              height: 6,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.budgetSpentOfLimit(
                formatVnd(category.spentAmount),
                formatVnd(category.limitAmount),
              ),
              style: context.moniaryTypography.metadata.copyWith(color: accent),
            ),
            if (category.isNearLimit || category.isOverLimit) ...[
              const SizedBox(height: 4),
              Text(
                category.isOverLimit
                    ? context.l10n.budgetOverLimit
                    : context.l10n.budgetNearLimit,
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: accent,
                ),
              ),
            ],
          ],
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
    return MoniaryEditorialCard(
      child: Column(
        children: [
          Icon(Icons.tune, size: 36, color: context.moniaryColors.primary),
          const SizedBox(height: 12),
          Text(
            context.l10n.budgetEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(context.l10n.budgetEmptyBody, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAdd,
            child: Text(context.l10n.budgetAddCategory),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
