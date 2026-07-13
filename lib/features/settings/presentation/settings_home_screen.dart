import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import 'account/active_sessions_screen.dart';
import 'account/delete_account_screen.dart';
import 'export/export_data_screen.dart';
import 'import/import_data_screen.dart';
import 'legal/terms_of_use_screen.dart';
import 'notifications/notification_settings_screen.dart';
import 'privacy/privacy_center_screen.dart';
import 'privacy/privacy_policy_screen.dart';
import 'support/help_center_screen.dart';
import 'widgets/settings_action_tile.dart';
import 'widgets/settings_group_card.dart';

class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({super.key});

  static const routePath = '/settings';

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ColoredBox(
        color: colors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
          children: [
            SettingsGroupCard(
              title: context.l10n.settingsAccountSection,
              children: [
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.verified_user_outlined,
                  title: context.l10n.activeSessionsTitle,
                  subtitle: '',
                  onTap: () => context.push(ActiveSessionsScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.privacyGroupDataSafetyTitle,
                  subtitle: context.l10n.privacyGroupDataSafetySubtitle,
                  onTap: () => context.push(
                    PrivacyCenterScreen.location(PrivacyCenterGroup.dataSafety),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsGroupCard(
              title: context.l10n.settingsDataSection,
              children: [
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.file_upload_outlined,
                  title: context.l10n.exportDataTitle,
                  subtitle: context.l10n.profileExportSubtitle,
                  onTap: () => context.push(ExportDataScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.file_download_outlined,
                  title: context.l10n.profileImportData,
                  subtitle: context.l10n.profileImportSubtitle,
                  onTap: () => context.push(ImportDataScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.notifications_outlined,
                  title: context.l10n.notificationSettings,
                  subtitle: '',
                  onTap: () =>
                      context.push(NotificationSettingsScreen.routePath),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsGroupCard(
              title: context.l10n.settingsLegalSupportSection,
              children: [
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.description_outlined,
                  title: context.l10n.termsOfUseTitle,
                  subtitle: context.l10n.termsOfUseSubtitle,
                  onTap: () => context.push(TermsOfUseScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.shield_outlined,
                  title: context.l10n.privacyPolicyTitle,
                  subtitle: context.l10n.privacyPolicySubtitle,
                  onTap: () => context.push(PrivacyPolicyScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.help_outline,
                  title: context.l10n.helpCenterTitle,
                  subtitle: context.l10n.privacyHelpCenterSubtitle,
                  onTap: () => context.push(HelpCenterScreen.routePath),
                ),
                SettingsActionTile(
                  grouped: true,
                  icon: Icons.delete_forever_outlined,
                  title: context.l10n.profileDeleteAccount,
                  subtitle: context.l10n.profileDeleteSubtitle,
                  destructive: true,
                  onTap: () => context.push(DeleteAccountScreen.routePath),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
