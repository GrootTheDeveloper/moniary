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
    final budgetAsync = ref.watch(monthlyBudgetProvider(args.month));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.budgetCategoryDetailTitle)),
      body: budgetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _BudgetCategoryDetailError(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(monthlyBudgetProvider(args.month)),
        ),
        data: (budget) {
          final categories = [
            ...budget.categories,
            ...budget.unbudgetedCategories,
          ];
          CategoryBudget? category;
          for (final item in categories) {
            if (item.categoryId == args.categoryId) {
              category = item;
              break;
            }
          }
          if (category == null) {
            return _BudgetCategoryDetailError(
              message: context.l10n.commonUnknown,
              onRetry: () => context.pop(),
            );
          }
          final selectedCategory = category;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(monthlyBudgetProvider(args.month)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
              children: [
                _BudgetCategoryHero(category: selectedCategory),
                MoniarySectionLabel(
                  context.l10n.budgetTransactionsInLimit,
                  trailing: TextButton.icon(
                    onPressed: () => BudgetLimitEditor.show(
                      context: context,
                      ref: ref,
                      month: args.month,
                      category: selectedCategory,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(context.l10n.budgetEditLimit),
                  ),
                ),
                if (selectedCategory.transactions.isEmpty)
                  MoniaryEditorialCard(
                    child: Text(
                      context.l10n.budgetNoTransactions,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (
                    var index = 0;
                    index < selectedCategory.transactions.length;
                    index++
                  )
                    _BudgetTransactionTile(
                      transaction: selectedCategory.transactions[index],
                      showTopDivider: index == 0,
                    ),
              ],
            ),
          );
        },
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
    final accent = category.isOverLimit
        ? colors.danger
        : category.isNearLimit
        ? colors.warning
        : AppColor.fromHex(category.categoryColor, fallback: colors.primary);
    final percent = (category.progress * 100).round();

    return MoniaryEditorialCard(
      radius: 26,
      padding: const EdgeInsets.all(22),
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
                  style: context.moniaryTypography.displayMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox.square(
              dimension: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 150,
                    child: CircularProgressIndicator(
                      value: category.progress,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: colors.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: context.moniaryTypography.displayLarge.copyWith(
                          color: accent,
                        ),
                      ),
                      Text(
                        context.l10n.budgetUsed,
                        style: context.moniaryTypography.metadata,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.l10n.budgetSpentOfLimit(
              formatVnd(category.spentAmount),
              formatVnd(category.limitAmount),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (category.isNearLimit || category.isOverLimit) ...[
            const SizedBox(height: 8),
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
    );
  }
}

class _BudgetTransactionTile extends StatelessWidget {
  const _BudgetTransactionTile({
    required this.transaction,
    required this.showTopDivider,
  });

  final TransactionEntry transaction;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final locale = Localizations.localeOf(context).toString();
    final note = transaction.note?.trim();
    final title = note?.isNotEmpty == true ? note! : transaction.categoryName;
    final date = DateFormat.MMMd(locale).format(transaction.transactionDate);
    final accent = AppColor.fromHex(
      transaction.categoryColor,
      fallback: AppTheme.sand,
    );

    return MoniaryHairlineTile(
      showTopDivider: showTopDivider,
      onTap: () => context.push(
        TransactionDetailScreen.routePath,
        extra: TransactionDetailRouteArgs(
          transaction: transaction,
          day: transaction.transactionDate,
        ),
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.receipt_long_outlined, color: accent, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        '$date · ${transaction.walletName}',
        style: TextStyle(color: colors.textDim),
      ),
      trailing: Text(
        formatVnd(transaction.amount),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: colors.danger,
        ),
      ),
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
