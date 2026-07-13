import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../../transactions/presentation/detail/transaction_detail_screen.dart';
import '../../transactions/presentation/detail/transaction_route_args.dart';
import '../application/budget_controller.dart';
import '../domain/monthly_budget.dart';
import 'widgets/budget_limit_editor.dart';

class BudgetCategoryDetailArgs {
  const BudgetCategoryDetailArgs({
    required this.month,
    required this.categoryId,
  });

  final DateTime month;
  final String categoryId;
}

class BudgetCategoryDetailScreen extends ConsumerWidget {
  const BudgetCategoryDetailScreen({required this.args, super.key});

  static const routePath = '/budgets/category';

  final BudgetCategoryDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final budgetAsync = ref.watch(monthlyBudgetProvider(args.month));

    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      body: budgetAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.primary)),
        error: (error, _) => _BudgetCategoryDetailError(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(monthlyBudgetProvider(args.month)),
        ),
        data: (budget) {
          final category = _findCategory(budget, args.categoryId);
          if (category == null) {
            return _BudgetCategoryDetailError(
              message: context.l10n.commonUnknown,
              onRetry: () => context.pop(),
            );
          }

          return _BudgetCategoryDetailBody(
            month: args.month,
            category: category,
            onRefresh: () async =>
                ref.invalidate(monthlyBudgetProvider(args.month)),
            onEdit: () => BudgetLimitEditor.show(
              context: context,
              ref: ref,
              month: args.month,
              category: category,
            ),
          );
        },
      ),
    );
  }
}

class _BudgetCategoryDetailBody extends StatelessWidget {
  const _BudgetCategoryDetailBody({
    required this.month,
    required this.category,
    required this.onRefresh,
    required this.onEdit,
  });

  final DateTime month;
  final CategoryBudget category;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;

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
              padding: const EdgeInsets.fromLTRB(36, 14, 36, 56),
              children: [
                _BudgetCategoryTopBar(category: category, onEdit: onEdit),
                const SizedBox(height: 26),
                _BudgetCategoryHero(category: category),
                const SizedBox(height: 24),
                _TransactionSection(category: category),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetCategoryTopBar extends StatelessWidget {
  const _BudgetCategoryTopBar({required this.category, required this.onEdit});

  final CategoryBudget category;
  final VoidCallback onEdit;

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
              context.go('/budgets');
            }
          },
        ),
        Expanded(
          child: Text(
            category.categoryName,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: colors.textPrimary,
              fontSize: 18,
              height: 1.05,
            ),
          ),
        ),
        _TopIconButton(
          icon: Icons.edit_outlined,
          tooltip: context.l10n.budgetEditLimit,
          onTap: onEdit,
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
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: _controlBorder(colors), width: 1.05),
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

class _BudgetCategoryHero extends StatelessWidget {
  const _BudgetCategoryHero({required this.category});

  final CategoryBudget category;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = _budgetAccent(category, colors);
    final percent = (category.progress * 100).round();
    final remaining = (category.limitAmount - category.spentAmount).clamp(
      0,
      double.infinity,
    );

    return Column(
      children: [
        SizedBox.square(
          dimension: 122,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: 122,
                child: CircularProgressIndicator(
                  value: category.progress,
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  backgroundColor: _controlBorder(
                    colors,
                  ).withValues(alpha: 0.45),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: context.moniaryTypography.displayMedium.copyWith(
                      color: colors.textPrimary,
                      fontSize: 26,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    context.l10n.budgetUsed.toUpperCase(),
                    style: context.moniaryTypography.metadata.copyWith(
                      color: colors.textDim,
                      fontSize: 7,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Text(
          context.l10n.budgetSpentRemainingLine(
            formatVnd(category.spentAmount),
            formatVnd(category.limitAmount),
            formatVnd(remaining.toDouble()),
          ),
          textAlign: TextAlign.center,
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: accent,
            fontSize: 10,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({required this.category});

  final CategoryBudget category;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final transactions = _sortedTransactions(category.transactions);
    final visible = transactions.take(4).toList();

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Text(
          context.l10n.budgetNoTransactions,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textDim),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n
              .budgetTransactionsInLimitCount(transactions.length)
              .toUpperCase(),
          style: context.moniaryTypography.metadata.copyWith(
            color: colors.textDim,
            fontSize: 7.4,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < visible.length; index++)
          _BudgetTransactionTile(
            transaction: visible[index],
            swatch: _transactionSwatch(index),
            showDivider: index > 0,
          ),
        const SizedBox(height: 17),
        Center(
          child: TextButton(
            onPressed: () => context.go('/statistics'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.terracotta,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(context.l10n.budgetViewAllInStats(transactions.length)),
          ),
        ),
      ],
    );
  }
}

class _BudgetTransactionTile extends StatelessWidget {
  const _BudgetTransactionTile({
    required this.transaction,
    required this.swatch,
    required this.showDivider,
  });

  final TransactionEntry transaction;
  final Color swatch;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final note = transaction.note?.trim();
    final title = note?.isNotEmpty == true ? note! : transaction.categoryName;

    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            color: _controlBorder(colors).withValues(alpha: 0.6),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(
              TransactionDetailScreen.routePath,
              extra: TransactionDetailRouteArgs(
                transaction: transaction,
                day: transaction.transactionDate,
              ),
            ),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _transactionTimeLabel(transaction.transactionDate),
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                            fontSize: 8,
                            letterSpacing: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatPlainAmount(transaction.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryDetailError extends StatelessWidget {
  const _BudgetCategoryDetailError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ColoredBox(
      color: colors.backgroundSoft,
      child: Center(
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
      ),
    );
  }
}

CategoryBudget? _findCategory(MonthlyBudget budget, String categoryId) {
  for (final category in [
    ...budget.categories,
    ...budget.unbudgetedCategories,
  ]) {
    if (category.categoryId == categoryId) {
      return category;
    }
  }
  return null;
}

List<TransactionEntry> _sortedTransactions(
  List<TransactionEntry> transactions,
) {
  final values = [...transactions];
  values.sort((a, b) {
    final aDay = DateTime(
      a.transactionDate.year,
      a.transactionDate.month,
      a.transactionDate.day,
    );
    final bDay = DateTime(
      b.transactionDate.year,
      b.transactionDate.month,
      b.transactionDate.day,
    );
    final dayCompare = bDay.compareTo(aDay);
    if (dayCompare != 0) return dayCompare;
    return a.transactionDate.compareTo(b.transactionDate);
  });
  return values;
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

Color _transactionSwatch(int index) {
  return const [
    Color(0xFFC9AE90),
    Color(0xFFB2918E),
    Color(0xFFB58E99),
    Color(0xFF8699B2),
  ][index % 4];
}

String _transactionTimeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} TH${date.month} · $hour:$minute';
}

String _formatPlainAmount(double amount) {
  return NumberFormat.decimalPattern('vi').format(amount.round());
}

Color _controlFill(MoniaryColors colors) {
  return Color.lerp(colors.backgroundSoft, colors.textPrimary, 0.025)!;
}

Color _controlBorder(MoniaryColors colors) {
  return Color.lerp(colors.outline, colors.textPrimary, 0.08)!;
}
