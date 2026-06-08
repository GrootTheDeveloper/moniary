import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../application/privacy_controller.dart';
import '../legal/data_deletion_policy_screen.dart';
import '../legal/policy_changelog_screen.dart';
import '../legal/terms_of_use_screen.dart';
import '../store/about_moniary_screen.dart';
import '../support/help_center_screen.dart';
import '../widgets/settings_action_tile.dart';
import '../widgets/settings_switch_tile.dart';
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
    final links = _linksFor(context);

    return Scaffold(
      appBar: AppBar(title: Text(group.title(context))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (group == PrivacyCenterGroup.dataSafety) ...[
              SettingsSwitchTile(
                icon: Icons.fingerprint,
                title: context.l10n.privacyCenterAppLockTitle,
                subtitle: context.l10n.privacyCenterAppLockSubtitle,
                value: privacyState.isAppLocked,
                onChanged: (val) => ref
                    .read(privacyControllerProvider.notifier)
                    .toggleAppLock(
                      val,
                      reason: context.l10n.biometricReasonEnable,
                    ),
              ),
            ],
            for (final link in links) ...[
              const SizedBox(height: 12),
              SettingsActionTile(
                icon: link.icon,
                title: link.title,
                subtitle: link.subtitle,
                onTap: () => context.push(link.routePath),
              ),
            ],
          ],
        ),
      ),
    );
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
          icon: Icons.info_outline,
          title: context.l10n.aboutMoniaryTitle,
          subtitle: context.l10n.privacyAboutSubtitle,
          routePath: AboutMoniaryScreen.routePath,
        ),
      ],
    };
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
}
