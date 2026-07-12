import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../application/privacy_controller.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../legal/data_deletion_policy_screen.dart';
import '../legal/policy_changelog_screen.dart';
import '../legal/terms_of_use_screen.dart';
import '../store/about_moniary_screen.dart';
import '../support/help_center_screen.dart';
import '../widgets/settings_action_tile.dart';
import '../widgets/settings_switch_tile.dart';
import '../widgets/settings_group_card.dart';
import '../widgets/settings_status_chip.dart';
import 'data_safety_screen.dart';
import 'permission_rationale_screen.dart';
import 'privacy_contact_screen.dart';
import 'privacy_policy_screen.dart';

enum PrivacyCenterGroup {
  privacyTerms('privacyTerms'),
  dataSafety('dataSafety'),
  helpRequests('helpRequests');

  const PrivacyCenterGroup(this.key);

  final String key;

  static PrivacyCenterGroup fromKey(String? key) {
    return PrivacyCenterGroup.values.firstWhere(
      (group) => group.key == key,
      orElse: () => PrivacyCenterGroup.privacyTerms,
    );
  }
}

class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({
    super.key,
    this.group = PrivacyCenterGroup.privacyTerms,
  });

  static const routePath = '/privacy-center';

  static String location(PrivacyCenterGroup group) {
    return '$routePath?group=${group.key}';
  }

  final PrivacyCenterGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyState = ref.watch(privacyControllerProvider);
    final requestHistory = ref.watch(privacyRequestHistoryProvider);
    final links = _linksFor(context);

    return Scaffold(
      appBar: AppBar(title: Text(group.title(context))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _PrivacyGroupHero(
              group: group,
              appLockEnabled: privacyState.isAppLocked,
              balancesHidden: privacyState.isBalancesHidden,
              requestHistory: requestHistory,
            ),
            const SizedBox(height: 20),
            if (group == PrivacyCenterGroup.helpRequests) ...[
              _PrivacyRequestSummaryCard(
                requestHistory: requestHistory,
                onTap: () => context.push(PrivacyContactScreen.routePath),
              ),
              const SizedBox(height: 20),
            ],
            if (group == PrivacyCenterGroup.dataSafety) ...[
              SettingsGroupCard(
                title: context.l10n.privacyProtectionSettingsTitle,
                children: [
                  SettingsSwitchTile(
                    grouped: true,
                    icon: Icons.fingerprint,
                    title: context.l10n.privacyCenterAppLockTitle,
                    subtitle: context.l10n.privacyCenterAppLockSubtitle,
                    value: privacyState.isAppLocked,
                    onChanged: (value) => _toggleAppLock(context, ref, value),
                  ),
                  SettingsSwitchTile(
                    grouped: true,
                    icon: Icons.visibility_off_outlined,
                    title: context.l10n.privacyHideBalancesTitle,
                    subtitle: context.l10n.privacyHideBalancesSubtitle,
                    value: privacyState.isBalancesHidden,
                    onChanged: (value) => _toggleBalances(context, ref, value),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            SettingsGroupCard(
              title: context.l10n.privacyExploreTitle,
              children: [
                for (final link in links)
                  SettingsActionTile(
                    grouped: true,
                    icon: link.icon,
                    title: link.title,
                    subtitle: link.subtitle,
                    status: link.routePath == PrivacyContactScreen.routePath
                        ? requestHistory.whenOrNull(
                            data: (items) => SettingsStatusChip(
                              label: context.l10n.privacyRequestCount(
                                items.length,
                              ),
                              tone: items.isEmpty
                                  ? SettingsStatusTone.neutral
                                  : SettingsStatusTone.info,
                            ),
                          )
                        : null,
                    onTap: () => context.push(link.routePath),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAppLock(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(privacyControllerProvider.notifier)
          .toggleAppLock(
            value,
            reason: value
                ? context.l10n.biometricReasonEnable
                : context.l10n.biometricReasonDisable,
          );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update app lock', error, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }

  Future<void> _toggleBalances(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(privacyControllerProvider.notifier)
          .toggleHideBalances(value);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to update balance visibility', error, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }

  List<_PrivacyLink> _linksFor(BuildContext context) {
    return switch (group) {
      PrivacyCenterGroup.privacyTerms => [
        _PrivacyLink(
          icon: Icons.privacy_tip_outlined,
          title: context.l10n.privacyPolicyTitle,
          subtitle: context.l10n.privacyTermsPolicySubtitle,
          routePath: PrivacyPolicyScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.gavel_outlined,
          title: context.l10n.privacyTermsLimitationsTitle,
          subtitle: context.l10n.privacyTermsLimitationsSubtitle,
          routePath: TermsOfUseScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.manage_history_outlined,
          title: context.l10n.privacyTermsRecordsTitle,
          subtitle: context.l10n.privacyTermsRecordsSubtitle,
          routePath: PolicyChangelogScreen.routePath,
        ),
      ],
      PrivacyCenterGroup.dataSafety => [
        _PrivacyLink(
          icon: Icons.verified_user_outlined,
          title: context.l10n.privacyDataOverviewTitle,
          subtitle: context.l10n.privacyDataOverviewSubtitle,
          routePath: DataSafetyScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.admin_panel_settings_outlined,
          title: context.l10n.permissionsTitle,
          subtitle: context.l10n.permissionsSubtitle,
          routePath: PermissionRationaleScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.manage_accounts_outlined,
          title: context.l10n.privacyDataControlsTitle,
          subtitle: context.l10n.privacyDataControlsSubtitle,
          routePath: DataDeletionPolicyScreen.routePath,
        ),
      ],
      PrivacyCenterGroup.helpRequests => [
        _PrivacyLink(
          icon: Icons.help_outlined,
          title: context.l10n.helpCenterTitle,
          subtitle: context.l10n.privacyHelpCenterSubtitle,
          routePath: HelpCenterScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.support_agent_outlined,
          title: context.l10n.privacyRequestsTitle,
          subtitle: context.l10n.privacyRequestsSubtitle,
          routePath: PrivacyContactScreen.routePath,
        ),
        _PrivacyLink(
          icon: Icons.info_outlined,
          title: context.l10n.aboutMoniaryTitle,
          subtitle: context.l10n.privacyAboutSubtitle,
          routePath: AboutMoniaryScreen.routePath,
        ),
      ],
    };
  }
}

class _PrivacyGroupHero extends StatelessWidget {
  const _PrivacyGroupHero({
    required this.group,
    required this.appLockEnabled,
    required this.balancesHidden,
    required this.requestHistory,
  });

  final PrivacyCenterGroup group;
  final bool appLockEnabled;
  final bool balancesHidden;
  final AsyncValue<List<PrivacyRequestHistoryEntry>> requestHistory;

  @override
  Widget build(BuildContext context) {
    final icon = switch (group) {
      PrivacyCenterGroup.privacyTerms => Icons.privacy_tip_outlined,
      PrivacyCenterGroup.dataSafety => Icons.verified_user_outlined,
      PrivacyCenterGroup.helpRequests => Icons.support_agent_outlined,
    };
    final color = switch (group) {
      PrivacyCenterGroup.privacyTerms => AppTheme.mintSoft,
      PrivacyCenterGroup.dataSafety => AppTheme.success,
      PrivacyCenterGroup.helpRequests => AppTheme.amber,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            AppTheme.surface.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      group.heroBody(context),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: _chips(context)),
        ],
      ),
    );
  }

  List<Widget> _chips(BuildContext context) {
    return switch (group) {
      PrivacyCenterGroup.privacyTerms => [
        SettingsStatusChip(
          label: context.l10n.privacyPolicyTitle,
          tone: SettingsStatusTone.info,
        ),
        SettingsStatusChip(
          label: context.l10n.termsOfUseTitle,
          tone: SettingsStatusTone.neutral,
        ),
      ],
      PrivacyCenterGroup.dataSafety => [
        SettingsStatusChip(
          label: context.l10n.privacyCenterAppLockTitle,
          tone: appLockEnabled
              ? SettingsStatusTone.success
              : SettingsStatusTone.warning,
        ),
        SettingsStatusChip(
          label: context.l10n.privacyHideBalancesTitle,
          tone: balancesHidden
              ? SettingsStatusTone.success
              : SettingsStatusTone.warning,
        ),
      ],
      PrivacyCenterGroup.helpRequests => [
        requestHistory.when(
          data: (items) => SettingsStatusChip(
            label: context.l10n.privacyRequestCount(items.length),
            tone: items.isEmpty
                ? SettingsStatusTone.neutral
                : SettingsStatusTone.info,
          ),
          loading: () => SettingsStatusChip(
            label: context.l10n.privacyStatusReview,
            tone: SettingsStatusTone.neutral,
          ),
          error: (_, _) => SettingsStatusChip(
            label: context.l10n.privacyStatusReview,
            tone: SettingsStatusTone.warning,
          ),
        ),
      ],
    };
  }
}

class _PrivacyRequestSummaryCard extends StatelessWidget {
  const _PrivacyRequestSummaryCard({
    required this.requestHistory,
    required this.onTap,
  });

  final AsyncValue<List<PrivacyRequestHistoryEntry>> requestHistory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = requestHistory.whenOrNull(data: (items) => items.length);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppTheme.mintSoft,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.privacyRequestsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == null
                        ? context.l10n.privacyGroupHelpRequestsSubtitle
                        : context.l10n.privacyRequestCount(count),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_outlined, color: AppTheme.mint),
          ],
        ),
      ),
    );
  }
}

class _PrivacyLink {
  const _PrivacyLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routePath,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String routePath;
}

extension on PrivacyCenterGroup {
  String title(BuildContext context) {
    return switch (this) {
      PrivacyCenterGroup.privacyTerms =>
        context.l10n.privacyGroupPrivacyTermsTitle,
      PrivacyCenterGroup.dataSafety => context.l10n.privacyGroupDataSafetyTitle,
      PrivacyCenterGroup.helpRequests =>
        context.l10n.privacyGroupHelpRequestsTitle,
    };
  }

  String heroBody(BuildContext context) {
    return switch (this) {
      PrivacyCenterGroup.privacyTerms =>
        context.l10n.privacyGroupPrivacyTermsSubtitle,
      PrivacyCenterGroup.dataSafety =>
        context.l10n.privacyGroupDataSafetySubtitle,
      PrivacyCenterGroup.helpRequests =>
        context.l10n.privacyGroupHelpRequestsSubtitle,
    };
  }
}
