import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../privacy/data_transparency_screen.dart';
import '../export/export_data_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class UserRightsSummaryScreen extends StatelessWidget {
  const UserRightsSummaryScreen({super.key});

  static const routePath = '/user-rights-summary';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalUserRights)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _RightsHero(),
            const SizedBox(height: 16),
            _RightItem(
              icon: Icons.visibility_outlined,
              title: context.l10n.userRightsAccessTitle,
              description: context.l10n.userRightsAccessDescription,
              onTap: () => context.push(DataTransparencyScreen.routePath),
            ),
            _RightItem(
              icon: Icons.file_download_outlined,
              title: context.l10n.userRightsExportTitle,
              description: context.l10n.userRightsExportDescription,
              onTap: () => context.push(ExportDataScreen.routePath),
            ),
            _RightItem(
              icon: Icons.edit_note_outlined,
              title: context.l10n.userRightsCorrectionTitle,
              description: context.l10n.userRightsCorrectionDescription,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            _RightItem(
              icon: Icons.delete_outlined,
              title: context.l10n.userRightsDeletionTitle,
              description: context.l10n.userRightsDeletionDescription,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightsHero extends StatelessWidget {
  const _RightsHero();

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
        context.l10n.userRightsHeroBody,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _RightItem extends StatelessWidget {
  const _RightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
            Icon(icon, color: AppTheme.mint),
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_outlined, color: AppTheme.mint),
          ],
        ),
      ),
    );
  }
}
