import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../application/notification_settings_controller.dart';
import '../../../../app/app_theme.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const routePath = '/notification-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationSettings)),
      body: state.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          children: [
            const SizedBox(height: 16),
            Text(
              context.l10n.emailReports,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.emailReportsDesc,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.mint),
            ),
            const SizedBox(height: 24),
            _buildSwitchTile(
              context: context,
              title: context.l10n.dailyReport,
              value: settings.dailyReminderEnabled,
              onChanged: (val) {
                ref
                    .read(notificationSettingsControllerProvider.notifier)
                    .updateDailyReminder(val);
              },
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              context: context,
              title: context.l10n.weeklyReport,
              value: settings.weeklySummaryEnabled,
              onChanged: (val) {
                ref
                    .read(notificationSettingsControllerProvider.notifier)
                    .updateWeeklySummary(val);
              },
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              context: context,
              title: context.l10n.monthlyReport,
              value: settings.monthlySummaryEnabled,
              onChanged: (val) {
                ref
                    .read(notificationSettingsControllerProvider.notifier)
                    .updateMonthlySummary(val);
              },
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              context: context,
              title: context.l10n.yearlyReport,
              value: settings.yearlySummaryEnabled,
              onChanged: (val) {
                ref
                    .read(notificationSettingsControllerProvider.notifier)
                    .updateYearlySummary(val);
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.errorGeneric,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(notificationSettingsControllerProvider),
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: SwitchListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.mint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
