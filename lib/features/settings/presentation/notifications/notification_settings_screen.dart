import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/notification_providers.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../application/notification_settings_controller.dart';
import '../../application/reminder_controller.dart';
import '../../domain/models/reminder_settings.dart';
import '../../../notifications/application/notification_delivery_preferences_controller.dart';
import '../../../notifications/data/repositories/notification_repository_impl.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const routePath = '/notification-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: const [
          _PushNotificationSection(),
          SizedBox(height: 28),
          _ReminderSection(),
          SizedBox(height: 28),
          _EmailReportsSection(),
        ],
      ),
    );
  }
}

class _PushNotificationSection extends ConsumerWidget {
  const _PushNotificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationDeliveryPreferencesControllerProvider);
    final controller = ref.read(
      notificationDeliveryPreferencesControllerProvider.notifier,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.pushNotificationSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.pushNotificationSectionDesc,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.mint),
        ),
        const SizedBox(height: 20),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorCard(
            onRetry: () => ref.invalidate(
              notificationDeliveryPreferencesControllerProvider,
            ),
          ),
          data: (preferences) => _SettingsCard(
            child: Column(
              children: [
                _NotificationTile(
                  icon: Icons.notifications_outlined,
                  title: context.l10n.pushNotificationAllTitle,
                  subtitle: context.l10n.pushNotificationAllSubtitle,
                  value: preferences.pushEnabled,
                  onChanged: (value) =>
                      _togglePush(context, ref, controller, value),
                ),
                const _SettingsDivider(),
                _PushCategoryTile(
                  icon: Icons.person_outline,
                  title: context.l10n.notificationsCategoryPersonal,
                  value: preferences.personalEnabled,
                  enabled: preferences.pushEnabled,
                  onChanged: (value) =>
                      controller.setCategoryEnabled('personal', value),
                ),
                const _SettingsDivider(),
                _PushCategoryTile(
                  icon: Icons.groups_outlined,
                  title: context.l10n.notificationsCategoryGroup,
                  value: preferences.groupEnabled,
                  enabled: preferences.pushEnabled,
                  onChanged: (value) =>
                      controller.setCategoryEnabled('group', value),
                ),
                const _SettingsDivider(),
                _PushCategoryTile(
                  icon: Icons.forum_outlined,
                  title: context.l10n.notificationsCategoryCommunity,
                  value: preferences.communityEnabled,
                  enabled: preferences.pushEnabled,
                  onChanged: (value) =>
                      controller.setCategoryEnabled('community', value),
                ),
                const _SettingsDivider(),
                _PushCategoryTile(
                  icon: Icons.settings_outlined,
                  title: context.l10n.notificationsCategorySystem,
                  value: preferences.systemEnabled,
                  enabled: preferences.pushEnabled,
                  onChanged: (value) =>
                      controller.setCategoryEnabled('system', value),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _togglePush(
    BuildContext context,
    WidgetRef ref,
    NotificationDeliveryPreferencesController controller,
    bool value,
  ) async {
    if (!value) {
      await controller.setPushEnabled(false);
      return;
    }

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final granted = await LocalNotificationService.instance.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderPermissionDenied)),
      );
      return;
    }

    await controller.setPushEnabled(true);
    await ref
        .read(fcmPushNotificationServiceProvider)
        .initialize(
          onToken: (token) => ref
              .read(notificationRepositoryProvider)
              .registerDevice(
                token: token,
                platform: defaultTargetPlatform == TargetPlatform.iOS
                    ? 'ios'
                    : 'android',
                locale: ref.read(preferredLocaleProvider),
                timezone: AppConstants.defaultTimezone,
              ),
          onTap: (_) async {},
        );
  }
}

class _PushCategoryTile extends StatelessWidget {
  const _PushCategoryTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _NotificationTile(
      icon: icon,
      title: title,
      subtitle: context.l10n.pushNotificationCategorySubtitle,
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// On-device daily reminder — delivered locally, independent of email reports.
class _ReminderSection extends ConsumerWidget {
  const _ReminderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderControllerProvider);
    final time = TimeOfDay(hour: settings.hour, minute: settings.minute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.reminderSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.reminderSectionDesc,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.mint),
        ),
        const SizedBox(height: 20),
        _SettingsCard(
          child: _NotificationTile(
            icon: Icons.notifications_active_outlined,
            title: context.l10n.reminderDailyTitle,
            subtitle: context.l10n.reminderDailyDesc(
              _formatTime(context, time),
            ),
            value: settings.enabled,
            onChanged: (val) => _toggle(context, ref, val),
            onTap: settings.enabled
                ? () => _changeTime(context, ref, settings)
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(reminderControllerProvider.notifier);

    if (!value) {
      await controller.disable();
      return;
    }

    final granted = await controller.enable(
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody,
    );
    if (!granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderPermissionDenied)),
      );
    }
  }

  Future<void> _changeTime(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings settings,
  ) async {
    final l10n = context.l10n;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;

    await ref
        .read(reminderControllerProvider.notifier)
        .setTime(
          hour: picked.hour,
          minute: picked.minute,
          title: l10n.reminderNotificationTitle,
          body: l10n.reminderNotificationBody,
        );
  }
}

/// Automated income/expense summaries delivered by email (Supabase function).
class _EmailReportsSection extends ConsumerWidget {
  const _EmailReportsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsControllerProvider);
    final notifier = ref.read(notificationSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        state.when(
          data: (settings) => _SettingsCard(
            child: Column(
              children: [
                _NotificationTile(
                  icon: Icons.today_outlined,
                  title: context.l10n.dailyReport,
                  subtitle: context.l10n.dailyReportDesc(
                    _formatTime(context, settings.dailyReminderTime),
                  ),
                  value: settings.dailyReminderEnabled,
                  onChanged: (val) => notifier.updateDailyReminder(val, null),
                ),
                const _SettingsDivider(),
                _NotificationTile(
                  icon: Icons.calendar_view_week_outlined,
                  title: context.l10n.weeklyReport,
                  subtitle: context.l10n.weeklyReportDesc,
                  value: settings.weeklySummaryEnabled,
                  onChanged: notifier.updateWeeklySummary,
                ),
                const _SettingsDivider(),
                _NotificationTile(
                  icon: Icons.calendar_month_outlined,
                  title: context.l10n.monthlyReport,
                  subtitle: context.l10n.monthlyReportDesc,
                  value: settings.monthlySummaryEnabled,
                  onChanged: notifier.updateMonthlySummary,
                ),
                const _SettingsDivider(),
                _NotificationTile(
                  icon: Icons.event_repeat_outlined,
                  title: context.l10n.yearlyReport,
                  subtitle: context.l10n.yearlyReportDesc,
                  value: settings.yearlySummaryEnabled,
                  onChanged: notifier.updateYearlySummary,
                ),
              ],
            ),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => _ErrorCard(
            onRetry: () =>
                ref.invalidate(notificationSettingsControllerProvider),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: child,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
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
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.errorGeneric,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
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

String _formatTime(BuildContext context, TimeOfDay? time) {
  final value = time ?? const TimeOfDay(hour: 20, minute: 0);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    value,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
