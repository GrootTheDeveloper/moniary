import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import 'help_center_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class SupportRequestChecklistScreen extends StatelessWidget {
  const SupportRequestChecklistScreen({super.key});

  static const routePath = '/support-request-checklist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.supportRequestChecklist)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ChecklistHero(),
            const SizedBox(height: 16),
            _ChecklistItem(
              title: context.l10n.supportChecklistActionTitle,
              description: context.l10n.supportChecklistActionDesc,
            ),
            _ChecklistItem(
              title: context.l10n.supportChecklistErrorTitle,
              description: context.l10n.supportChecklistErrorDesc,
            ),
            _ChecklistItem(
              title: context.l10n.supportChecklistFileTitle,
              description: context.l10n.supportChecklistFileDesc,
            ),
            _ChecklistItem(
              title: context.l10n.supportChecklistDiagnosticTitle,
              description: context.l10n.supportChecklistDiagnosticDesc,
            ),
            _ChecklistItem(
              title: context.l10n.supportChecklistSensitiveTitle,
              description: context.l10n.supportChecklistSensitiveDesc,
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(HelpCenterScreen.routePath),
              icon: const Icon(Icons.help_outlined),
              label: Text(context.l10n.supportOpenHelpCenter),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
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

class _ChecklistHero extends StatelessWidget {
  const _ChecklistHero();

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
        context.l10n.supportChecklistHero,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.title, required this.description});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_outlined,
              color: AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
