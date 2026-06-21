import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../application/account/account_actions_controller.dart';
import '../../application/privacy_controller.dart';
import '../../domain/account/deletion_feedback.dart';
import '../../domain/transparency/data_transparency_summary.dart';
import '../export/export_data_screen.dart';
import '../widgets/settings_danger_card.dart';
import '../widgets/settings_info_banner.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const routePath = '/delete-account';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _detailsController = TextEditingController();
  final _confirmationController = TextEditingController();
  AccountDeletionReason? _reason;
  bool _understood = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  bool _isConfirmed({required bool isGuest}) =>
      _understood &&
      (isGuest || _reason != null) &&
      _confirmationController.text.trim().toUpperCase() ==
          context.l10n.deleteAccountConfirmationPhrase.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(accountActionsControllerProvider);
    final summary = ref.watch(dataTransparencySummaryProvider);
    final isGuest = ref.watch(useMockDataModeProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          AppLogger.error('Account deletion failed', error, stackTrace);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGuest
              ? context.l10n.deleteGuestDataTitle
              : context.l10n.deleteAccountTitle,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                SettingsDangerCard(
                  title: isGuest
                      ? context.l10n.deleteGuestDataTitle
                      : context.l10n.deleteAccountGraceTitle,
                  body: isGuest
                      ? context.l10n.deleteGuestDataBody
                      : context.l10n.deleteAccountGraceBody,
                ),
                const SizedBox(height: 16),
                _DataImpactCard(summary: summary),
                const SizedBox(height: 16),
                SettingsInfoBanner(
                  icon: Icons.download_outlined,
                  title: context.l10n.deleteAccountExportTitle,
                  body: context.l10n.deleteAccountExportBody,
                  action: TextButton.icon(
                    onPressed: () => context.push(ExportDataScreen.routePath),
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: Text(context.l10n.deleteAccountExportAction),
                  ),
                ),
                if (!isGuest) ...[
                  const SizedBox(height: 22),
                  Text(
                    context.l10n.deleteAccountReasonTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AccountDeletionReason>(
                    initialValue: _reason,
                    decoration: InputDecoration(
                      hintText: context.l10n.deleteAccountReasonHint,
                    ),
                    items: AccountDeletionReason.values
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(_reasonLabel(context, reason)),
                          ),
                        )
                        .toList(),
                    onChanged: action.isLoading
                        ? null
                        : (value) => setState(() => _reason = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailsController,
                    enabled: !action.isLoading,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: context.l10n.deleteAccountDetailsLabel,
                      hintText: context.l10n.deleteAccountDetailsHint,
                      helperText: context.l10n.deleteAccountDetailsHelper,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                CheckboxListTile(
                  value: _understood,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.danger,
                  title: Text(
                    isGuest
                        ? context.l10n.deleteGuestDataUnderstand
                        : context.l10n.deleteAccountGraceUnderstand,
                  ),
                  onChanged: action.isLoading
                      ? null
                      : (value) => setState(() => _understood = value ?? false),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmationController,
                  enabled: !action.isLoading,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.l10n.deleteAccountConfirmationLabel(
                      context.l10n.deleteAccountConfirmationPhrase,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: FilledButton.icon(
                onPressed: !action.isLoading && _isConfirmed(isGuest: isGuest)
                    ? () => _submit(isGuest: isGuest)
                    : null,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                icon: action.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined),
                label: Text(
                  isGuest
                      ? context.l10n.deleteGuestDataAction
                      : context.l10n.deleteAccountScheduleAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit({required bool isGuest}) async {
    FocusScope.of(context).unfocus();
    if (isGuest) {
      // Guest reset is completed by the dedicated controller later in this flow.
      await ref
          .read(accountActionsControllerProvider.notifier)
          .deleteGuestData();
    } else {
      bool authenticated;
      try {
        authenticated = await ref
            .read(privacyControllerProvider.notifier)
            .authenticateUser(
              context.l10n.biometricReasonDeleteAccount,
              allowUnavailable: true,
            );
      } catch (error, stackTrace) {
        AppLogger.error(
          'Account deletion authentication failed',
          error,
          stackTrace,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        }
        return;
      }
      if (!authenticated || !mounted) return;

      await ref
          .read(accountActionsControllerProvider.notifier)
          .requestSoftDelete(
            reason: _reason!,
            details: _detailsController.text,
            feedbackContext: DeletionFeedbackContext(
              appVersion: AppConstants.appVersion,
              platform: defaultTargetPlatform.name,
              locale: Localizations.localeOf(context).toLanguageTag(),
            ),
          );
    }

    if (!mounted || ref.read(accountActionsControllerProvider).hasError) return;
    context.go(LoginScreen.routePath);
  }

  String _reasonLabel(BuildContext context, AccountDeletionReason reason) {
    return switch (reason) {
      AccountDeletionReason.difficultToUse =>
        context.l10n.deleteReasonDifficultToUse,
      AccountDeletionReason.missingFeatures =>
        context.l10n.deleteReasonMissingFeatures,
      AccountDeletionReason.technicalIssues =>
        context.l10n.deleteReasonTechnicalIssues,
      AccountDeletionReason.privacyConcerns =>
        context.l10n.deleteReasonPrivacyConcerns,
      AccountDeletionReason.noLongerNeeded =>
        context.l10n.deleteReasonNoLongerNeeded,
      AccountDeletionReason.other => context.l10n.deleteReasonOther,
    };
  }
}

class _DataImpactCard extends StatelessWidget {
  const _DataImpactCard({required this.summary});

  final AsyncValue<DataTransparencySummary> summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.deleteAccountImpactTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          summary.when(
            data: (value) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ImpactMetric(
                  label: context.l10n.deleteAccountTransactionsCount(
                    value.transactionCount,
                  ),
                ),
                _ImpactMetric(
                  label: context.l10n.deleteAccountWalletsCount(
                    value.walletCount,
                  ),
                ),
                _ImpactMetric(
                  label: context.l10n.deleteAccountPhotosCount(
                    value.photoTransactionCount,
                  ),
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(
              context.l10n.deleteAccountImpactUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
