import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';

class DataRetentionPolicyScreen extends StatelessWidget {
  const DataRetentionPolicyScreen({super.key});

  static const routePath = '/data-retention-policy';

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.cloud_outlined,
        title: context.l10n.dataRetentionCloudTitle,
        description: context.l10n.dataRetentionCloudDesc,
      ),
      (
        icon: Icons.photo_library_outlined,
        title: context.l10n.dataRetentionPhotosTitle,
        description: context.l10n.dataRetentionPhotosDesc,
      ),
      (
        icon: Icons.folder_outlined,
        title: context.l10n.dataRetentionLocalFilesTitle,
        description: context.l10n.dataRetentionLocalFilesDesc,
      ),
      (
        icon: Icons.delete_outlined,
        title: context.l10n.dataRetentionDeleteTitle,
        description: context.l10n.dataRetentionDeleteDesc,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dataRetentionPolicyTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _RetentionHero(message: context.l10n.dataRetentionPolicySubtitle),
            const SizedBox(height: 16),
            ...items.map(
              (item) => _RetentionItem(
                icon: item.icon,
                title: item.title,
                description: item.description,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetentionHero extends StatelessWidget {
  const _RetentionHero({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _RetentionItem extends StatelessWidget {
  const _RetentionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
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
        ],
      ),
    );
  }
}
