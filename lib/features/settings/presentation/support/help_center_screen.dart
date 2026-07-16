import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../domain/store/app_release_info.dart';
import '../account/delete_account_help_screen.dart';
import '../export/export_data_screen.dart';
import '../export/export_troubleshooting_screen.dart';
import '../privacy/privacy_account_faq_screen.dart';
import '../privacy/privacy_contact_screen.dart';
import 'support_request_checklist_screen.dart';
import '../legal/user_rights_summary_screen.dart';
import '../widgets/settings_action_tile.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const routePath = '/help-center';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.supportHelpCenter)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _HelpHero(),
            const SizedBox(height: 16),
            const _DiagnosticCard(),
            const SizedBox(height: 16),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.privacy_tip_outlined,
              title: context.l10n.privacyAndAccountTitle,
              subtitle: context.l10n.privacyAndAccountSubtitle,
              onTap: () => context.push(PrivacyAccountFaqScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.assignment_ind_outlined,
              title: context.l10n.dataRightsTitle,
              subtitle: context.l10n.dataRightsSubtitle,
              onTap: () => context.push(UserRightsSummaryScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.file_download_outlined,
              title: context.l10n.exportDataTitle,
              subtitle: context.l10n.exportDataSubTitle,
              onTap: () => context.push(ExportTroubleshootingScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.download_done_outlined,
              title: context.l10n.createExportFileTitle,
              subtitle: context.l10n.createExportFileSubtitle,
              onTap: () => context.push(ExportDataScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.support_agent_outlined,
              title: context.l10n.supportContactTitle,
              subtitle: context.l10n.contactSupportSubtitle,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.delete_forever_outlined,
              title: context.l10n.deleteAccountTitle,
              subtitle: context.l10n.deleteAccountSubtitle,
              onTap: () => context.push(DeleteAccountHelpScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.fact_check_outlined,
              title: context.l10n.supportChecklistTitle,
              subtitle: context.l10n.supportChecklistSubtitle,
              onTap: () =>
                  context.push(SupportRequestChecklistScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        context.l10n.helpHeroText,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard();

  @override
  Widget build(BuildContext context) {
    final diagnostic =
        'App: ${appReleaseInfo.name}\n'
        'Version: ${appReleaseInfo.version}\n'
        'Build: ${appReleaseInfo.buildNumber}\n'
        'Channel: ${appReleaseInfo.releaseChannel}\n'
        'Support: ${context.l10n.privacyInAppChannelValue}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: AppTheme.mint),
              const SizedBox(width: 8),
              Text(
                context.l10n.supportDiagnosticTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.supportDiagnosticSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagnostic));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.supportCopySuccess)),
              );
            },
            icon: const Icon(Icons.content_copy_outlined),
            label: Text(context.l10n.supportCopyDiagnostic),
          ),
        ],
      ),
    );
  }
}
