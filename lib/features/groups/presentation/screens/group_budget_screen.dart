import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/integer_money_input_formatter.dart';
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
    final transactionsAsync = ref.watch(
      groupTransactionsProvider(widget.groupId),
    );
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
          final now = DateTime.now();
          final spentThisMonth = transactionsAsync.asData?.value
              .where(
                (transaction) =>
                    transaction.splitStatus == GroupSplitStatus.posted &&
                    transaction.transactionDate.year == now.year &&
                    transaction.transactionDate.month == now.month,
              )
              .fold<int>(
                0,
                (sum, transaction) => sum + transaction.baseTotalAmount,
              );
          final spent = spentThisMonth ?? 0;
          final progress = budget.hasLimit
              ? (spent / budget.monthlyLimit).clamp(0.0, 1.0).toDouble()
              : 0.0;
          final isOverLimit = budget.hasLimit && spent > budget.monthlyLimit;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
            children: [
              Text(
                context.l10n.groupBudgetSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.groupBudgetProgressTitle),
                      const SizedBox(height: 8),
                      Text(
                        budget.hasLimit
                            ? context.l10n.groupBudgetSpentOfLimit(
                                ref.formatAmount(spent),
                                ref.formatAmount(budget.monthlyLimit),
                              )
                            : context.l10n.groupBudgetNoLimit,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (budget.hasLimit) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          color: isOverLimit ? colors.danger : colors.primary,
                          backgroundColor: colors.outline.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOverLimit
                              ? context.l10n.groupBudgetOverLimit
                              : context.l10n.groupBudgetThresholdNotice(
                                  budget.warningThresholdPercent,
                                ),
                          style: TextStyle(
                            color: isOverLimit
                                ? colors.danger
                                : colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _limitController,
                enabled: canEdit,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  IntegerMoneyInputFormatter(
                    locale: Localizations.localeOf(context).toString(),
                  ),
                ],
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
    final limit = parseIntegerMoney(_limitController.text);
    if (_limitController.text.trim().isEmpty || limit < 0) {
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
