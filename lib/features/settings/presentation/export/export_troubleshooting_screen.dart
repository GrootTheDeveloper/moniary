import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import 'export_data_screen.dart';
import 'export_history_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class ExportTroubleshootingScreen extends StatelessWidget {
  const ExportTroubleshootingScreen({super.key});

  static const routePath = '/export-troubleshooting';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.exportSupportTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ExportHelpHero(),
            const SizedBox(height: 16),
            _TroubleshootingStep(
              title: context.l10n.exportTroubleshootingTypeTitle,
              description: context.l10n.exportTroubleshootingTypeDesc,
            ),
            _TroubleshootingStep(
              title: context.l10n.exportTroubleshootingDateTitle,
              description: context.l10n.exportTroubleshootingDateDesc,
            ),
            _TroubleshootingStep(
              title: context.l10n.exportTroubleshootingHistoryTitle,
              description: context.l10n.exportTroubleshootingHistoryDesc,
            ),
            _TroubleshootingStep(
              title: context.l10n.exportTroubleshootingSupportTitle,
              description: context.l10n.exportTroubleshootingSupportDesc,
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportDataScreen.routePath),
              icon: const Icon(Icons.file_download_outlined),
              label: Text(context.l10n.exportOpenData),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportHistoryScreen.routePath),
              icon: const Icon(Icons.history_outlined),
              label: Text(context.l10n.exportOpenHistory),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(PrivacyContactScreen.routePath),
              icon: const Icon(Icons.support_agent_outlined),
              label: Text(context.l10n.exportCreateSupportRequest),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportHelpHero extends StatelessWidget {
  const _ExportHelpHero();

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
        context.l10n.exportTroubleshootingHero,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _TroubleshootingStep extends StatelessWidget {
  const _TroubleshootingStep({required this.title, required this.description});

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
