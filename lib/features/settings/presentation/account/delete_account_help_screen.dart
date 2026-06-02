import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';
import 'deletion_request_screen.dart';
import '../export/export_data_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class DeleteAccountHelpScreen extends StatelessWidget {
  const DeleteAccountHelpScreen({super.key});

  static const routePath = '/delete-account-help';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deleteAccountHelpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _DeleteHelpHero(),
            const SizedBox(height: 16),
            _DeleteHelpStep(
              title: context.l10n.deleteAccountHelpStep1Title,
              description: context.l10n.deleteAccountHelpStep1Desc,
            ),
            _DeleteHelpStep(
              title: context.l10n.deleteAccountHelpStep2Title,
              description: context.l10n.deleteAccountHelpStep2Desc,
            ),
            _DeleteHelpStep(
              title: context.l10n.deleteAccountHelpStep3Title,
              description: context.l10n.deleteAccountHelpStep3Desc,
            ),
            _DeleteHelpStep(
              title: context.l10n.deleteAccountHelpStep4Title,
              description: context.l10n.deleteAccountHelpStep4Desc,
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportDataScreen.routePath),
              icon: const Icon(Icons.file_download_outlined),
              label: Text(context.l10n.deleteAccountHelpExportBefore),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(DeletionRequestScreen.routePath),
              icon: const Icon(Icons.description_outlined),
              label: Text(context.l10n.deleteAccountHelpCreateRequest),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(PrivacyContactScreen.routePath),
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(context.l10n.deleteAccountHelpContactPrivacy),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteHelpHero extends StatelessWidget {
  const _DeleteHelpHero();

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
        context.l10n.deleteAccountHelpHero,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DeleteHelpStep extends StatelessWidget {
  const _DeleteHelpStep({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
