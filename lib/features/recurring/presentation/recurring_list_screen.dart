import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../../settings/application/alert_preferences_controller.dart';
import '../application/bill_reminder_scheduler.dart';
import '../application/recurring_controller.dart';
import '../domain/models/recurring_rule.dart';
import 'recurring_rule_sheet.dart';

class RecurringListScreen extends ConsumerStatefulWidget {
  const RecurringListScreen({super.key});

  static const routePath = '/recurring';

  @override
  ConsumerState<RecurringListScreen> createState() =>
      _RecurringListScreenState();
}

class _RecurringListScreenState extends ConsumerState<RecurringListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Post any due auto-rules, then keep reminders in sync.
      await ref.read(recurringControllerProvider.notifier).materializeDue();
      await _syncReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final rulesAsync = ref.watch(recurringRulesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(context.l10n.recurringTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.commonAdd),
      ),
      body: rulesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.mint),
        ),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (rules) => rules.isEmpty
            ? _EmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(recurringRulesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  itemCount: rules.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) return _header(context);
                    final rule = rules[index - 1];
                    return _RuleCard(
                      rule: rule,
                      onTap: () => _openEdit(rule),
                      onToggle: (value) => _toggle(rule, value),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        context.l10n.recurringSubtitle,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.moniaryColors.textDim),
      ),
    );
  }

  Future<void> _openCreate() async {
    final saved = await showRecurringRuleSheet(context);
    if (saved == true) await _syncReminders();
  }

  Future<void> _openEdit(RecurringRule rule) async {
    final saved = await showRecurringRuleSheet(context, initial: rule);
    if (saved == true) await _syncReminders();
  }

  Future<void> _toggle(RecurringRule rule, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(recurringControllerProvider.notifier)
          .toggleActive(rule.id, value);
      await _syncReminders();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  /// Re-schedules bill reminders from the current rules when the feature is on.
  Future<void> _syncReminders() async {
    final prefs = ref.read(alertPreferencesControllerProvider);
    if (!prefs.billRemindersEnabled) return;
    if (!mounted) return;

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final rules = await ref.read(recurringRulesProvider.future);

    await ref
        .read(billReminderSchedulerProvider)
        .reschedule(
          rules: rules,
          leadDays: prefs.billLeadDays,
          title: l10n.billReminderNotifTitle,
          bodyBuilder: (rule, dueDate) => l10n.billReminderNotifBody(
            (rule.note?.trim().isNotEmpty ?? false)
                ? rule.note!.trim()
                : rule.categoryName,
            DateFormat.yMMMd(locale).format(dueDate),
          ),
        );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onTap,
    required this.onToggle,
  });

  final RecurringRule rule;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = AppColor.fromHex(
      rule.categoryColor ?? rule.walletColor,
      fallback: AppTheme.amber,
    );
    final locale = Localizations.localeOf(context).toString();
    final title = (rule.note?.trim().isNotEmpty ?? false)
        ? rule.note!.trim()
        : rule.categoryName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              child: Icon(
                rule.autoPost ? Icons.autorenew : Icons.notifications_outlined,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${recurringScheduleLabel(context, rule)} · '
                    '${context.l10n.recurringNextRun(DateFormat.MMMd(locale).format(rule.nextRunDate))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textDim),
                  ),
                  const SizedBox(height: 6),
                  _Badge(
                    label: rule.autoPost
                        ? context.l10n.recurringAutoPost
                        : context.l10n.recurringRemindOnly,
                    color: rule.autoPost ? AppTheme.mint : colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ObscurableAmountText(
                  prefixText: rule.isIncome ? '+' : '-',
                  amountText: _money(context, rule.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rule.isIncome ? AppTheme.success : AppTheme.danger,
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: rule.isActive,
                    onChanged: onToggle,
                    activeThumbColor: AppTheme.mint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_repeat_outlined, size: 64, color: colors.textDim),
            const SizedBox(height: 12),
            Text(
              context.l10n.recurringEmptyTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.recurringEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textDim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(BuildContext context, double amount) => formatMoney(amount);
