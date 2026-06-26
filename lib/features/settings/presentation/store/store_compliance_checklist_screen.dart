import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class StoreComplianceChecklistScreen extends StatelessWidget {
  const StoreComplianceChecklistScreen({super.key});

  static const routePath = '/store-compliance-checklist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.storeComplianceChecklist)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ChecklistHero(),
            const SizedBox(height: 16),
            _ChecklistItem(
              title: context.l10n.storeCompliancePrivacyTitle,
              description: context.l10n.storeCompliancePrivacyDesc,
            ),
            _ChecklistItem(
              title: context.l10n.storeComplianceDeleteTitle,
              description: context.l10n.storeComplianceDeleteDesc,
            ),
            _ChecklistItem(
              title: context.l10n.storeComplianceExportTitle,
              description: context.l10n.storeComplianceExportDesc,
            ),
            _ChecklistItem(
              title: context.l10n.storeComplianceDataSafetyTitle,
              description: context.l10n.storeComplianceDataSafetyDesc,
            ),
            _ChecklistItem(
              title: context.l10n.storeComplianceContactTitle,
              description: context.l10n.storeComplianceContactDesc,
            ),
            _ChecklistItem(
              title: context.l10n.storeComplianceTermsTitle,
              description: context.l10n.storeComplianceTermsDesc,
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
        context.l10n.storeComplianceHero,
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
