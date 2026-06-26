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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
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
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.today_outlined,
                    title: context.l10n.dailyReport,
                    subtitle: context.l10n.dailyReportDesc(
                      _formatReportTime(context, settings.dailyReminderTime),
                    ),
                    value: settings.dailyReminderEnabled,
                    onChanged: (val) {
                      ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .updateDailyReminder(val, null);
                    },
                  ),
                  const _SettingsDivider(),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.calendar_view_week_outlined,
                    title: context.l10n.weeklyReport,
                    subtitle: context.l10n.weeklyReportDesc,
                    value: settings.weeklySummaryEnabled,
                    onChanged: (val) {
                      ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .updateWeeklySummary(val);
                    },
                  ),
                  const _SettingsDivider(),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    title: context.l10n.monthlyReport,
                    subtitle: context.l10n.monthlyReportDesc,
                    value: settings.monthlySummaryEnabled,
                    onChanged: (val) {
                      ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .updateMonthlySummary(val);
                    },
                  ),
                  const _SettingsDivider(),
                  _buildSwitchTile(
                    context: context,
                    icon: Icons.event_repeat_outlined,
                    title: context.l10n.yearlyReport,
                    subtitle: context.l10n.yearlyReportDesc,
                    value: settings.yearlySummaryEnabled,
                    onChanged: (val) {
                      ref
                          .read(notificationSettingsControllerProvider.notifier)
                          .updateYearlySummary(val);
                    },
                  ),
                ],
              ),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.mint,
          ),
        ],
      ),
    );
  }

  String _formatReportTime(BuildContext context, TimeOfDay? time) {
    final reportTime = time ?? const TimeOfDay(hour: 20, minute: 0);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      reportTime,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: AppTheme.outline,
    );
  }
}
