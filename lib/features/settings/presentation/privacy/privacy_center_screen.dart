import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../application/account/account_actions_controller.dart';
import '../account/deletion_request_screen.dart';
import '../export/export_data_screen.dart';
import '../export/export_history_screen.dart';
import '../legal/data_deletion_policy_screen.dart';
import '../legal/data_retention_policy_screen.dart';
import '../legal/financial_disclaimer_screen.dart';
import '../legal/legal_contact_screen.dart';
import '../legal/policy_acceptance_notice_screen.dart';
import '../legal/policy_changelog_screen.dart';
import '../legal/terms_of_use_screen.dart';
import '../legal/third_party_services_screen.dart';
import '../legal/user_rights_summary_screen.dart';
import '../store/about_moniary_screen.dart';
import '../store/store_compliance_checklist_screen.dart';
import '../store/trust_safety_screen.dart';
import '../support/help_center_screen.dart';
import '../widgets/settings_action_tile.dart';
import 'data_safety_screen.dart';
import 'data_transparency_screen.dart';
import 'permission_rationale_screen.dart';
import 'privacy_contact_screen.dart';
import 'privacy_policy_screen.dart';
import '../widgets/delete_account_dialog.dart';
import '../../application/privacy_controller.dart';
import '../widgets/settings_switch_tile.dart';

class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  static const routePath = '/privacy-center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountActionsControllerProvider);
    final privacyState = ref.watch(privacyControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyCenter)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _PrivacyHero(),
                const SizedBox(height: 18),
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
                const SizedBox(height: 12),
                SettingsSwitchTile(
                  icon: Icons.visibility_off_outlined,
                  title: context.l10n.privacyCenterHideBalancesTitle,
                  subtitle: context.l10n.privacyCenterHideBalancesSubtitle,
                  value: privacyState.isBalancesHidden,
                  onChanged: (val) => ref
                      .read(privacyControllerProvider.notifier)
                      .toggleHideBalances(val),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.help_outlined,
                  title: context.l10n.helpCenterTitle,
                  subtitle: context.l10n.helpCenterSubtitle,
                  onTap: () => context.push(HelpCenterScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.info_outline,
                  title: context.l10n.aboutMoniaryTitle,
                  subtitle: context.l10n.aboutMoniarySubtitle,
                  onTap: () => context.push(AboutMoniaryScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: context.l10n.privacyPolicyTitle,
                  subtitle: context.l10n.privacyPolicySubtitle,
                  onTap: () => context.push(PrivacyPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.gavel_outlined,
                  title: context.l10n.termsOfUseTitle,
                  subtitle: context.l10n.termsOfUseSubtitle,
                  onTap: () => context.push(TermsOfUseScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.inventory_2_outlined,
                  title: context.l10n.dataRetentionPolicyTitle,
                  subtitle: context.l10n.dataRetentionPolicySubtitle,
                  onTap: () =>
                      context.push(DataRetentionPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.hub_outlined,
                  title: context.l10n.thirdPartyServicesTitle,
                  subtitle: context.l10n.thirdPartyServicesSubtitle,
                  onTap: () => context.push(ThirdPartyServicesScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.fact_check_outlined,
                  title: context.l10n.releaseChecklistTitle,
                  subtitle: context.l10n.releaseChecklistSubtitle,
                  onTap: () =>
                      context.push(StoreComplianceChecklistScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.health_and_safety_outlined,
                  title: context.l10n.trustSafetyTitle,
                  subtitle: context.l10n.trustSafetySubtitle,
                  onTap: () => context.push(TrustSafetyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.account_balance_outlined,
                  title: context.l10n.financialDisclaimerTitle,
                  subtitle: context.l10n.financialDisclaimerSubtitle,
                  onTap: () =>
                      context.push(FinancialDisclaimerScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.manage_history_outlined,
                  title: context.l10n.policyChangelogTitle,
                  subtitle: context.l10n.policyChangelogSubtitle,
                  onTap: () => context.push(PolicyChangelogScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.assignment_ind_outlined,
                  title: context.l10n.userDataRightsTitle,
                  subtitle: context.l10n.userDataRightsSubtitle,
                  onTap: () => context.push(UserRightsSummaryScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.verified_outlined,
                  title: context.l10n.policyAcceptanceNoticeTitle,
                  subtitle: context.l10n.policyAcceptanceNoticeSubtitle,
                  onTap: () =>
                      context.push(PolicyAcceptanceNoticeScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.contact_mail_outlined,
                  title: context.l10n.legalContactTitle,
                  subtitle: context.l10n.legalContactSubtitle,
                  onTap: () => context.push(LegalContactScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.verified_user_outlined,
                  title: context.l10n.dataSafetyTitle,
                  subtitle: context.l10n.dataSafetySubtitle,
                  onTap: () => context.push(DataSafetyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.dataset_outlined,
                  title: context.l10n.myDataTitle,
                  subtitle: context.l10n.myDataSubtitle,
                  onTap: () => context.push(DataTransparencyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: context.l10n.permissionsTitle,
                  subtitle: context.l10n.permissionsSubtitle,
                  onTap: () =>
                      context.push(PermissionRationaleScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.file_download_outlined,
                  title: context.l10n.exportMyDataTitle,
                  subtitle: context.l10n.exportMyDataSubtitle,
                  onTap: () => context.push(ExportDataScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.history_outlined,
                  title: context.l10n.exportHistoryTitle,
                  subtitle: context.l10n.exportHistorySubtitle,
                  onTap: () => context.push(ExportHistoryScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: context.l10n.deleteAccountTitle,
                  subtitle: context.l10n.deleteAccountSubtitle2,
                  destructive: true,
                  onTap: state.isLoading
                      ? null
                      : () => _confirmDelete(context, ref),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.policy_outlined,
                  title: context.l10n.dataDeletionPolicyTitle,
                  subtitle: context.l10n.dataDeletionPolicySubtitle,
                  onTap: () => context.push(DataDeletionPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.description_outlined,
                  title: context.l10n.dataDeletionRequestTitle,
                  subtitle: context.l10n.dataDeletionRequestSubtitle,
                  onTap: () => context.push(DeletionRequestScreen.routePath),
                ),
                const SizedBox(height: 12),
                SettingsActionTile(
                  icon: Icons.support_agent_outlined,
                  title: context.l10n.privacyContactTitle,
                  subtitle: context.l10n.privacyContactSubtitle,
                  onTap: () => context.push(PrivacyContactScreen.routePath),
                ),
              ],
            ),
            if (state.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(accountActionsControllerProvider.notifier).deleteAccount();
    if (context.mounted &&
        !ref.read(accountActionsControllerProvider).hasError) {
      context.go(LoginScreen.routePath);
    }
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.mint),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.privacyHeroTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.privacyHeroSubtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
