import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';

class PolicyChangelogScreen extends StatelessWidget {
  const PolicyChangelogScreen({super.key});

  static const routePath = '/policy-changelog';

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        date: '27/05/2026',
        title: context.l10n.policyChangelogEntry1Title,
        description: context.l10n.policyChangelogEntry1Desc,
      ),
      (
        date: '26/05/2026',
        title: context.l10n.policyChangelogEntry2Title,
        description: context.l10n.policyChangelogEntry2Desc,
      ),
      (
        date: '26/05/2026',
        title: context.l10n.policyChangelogEntry3Title,
        description: context.l10n.policyChangelogEntry3Desc,
      ),
      (
        date: '25/05/2026',
        title: context.l10n.policyChangelogEntry4Title,
        description: context.l10n.policyChangelogEntry4Desc,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.policyChangelogTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _ChangelogHero(message: context.l10n.policyChangelogSubtitle),
            const SizedBox(height: 16),
            ...items.map(
              (item) => _ChangelogItem(
                date: item.date,
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

class _ChangelogHero extends StatelessWidget {
  const _ChangelogHero({required this.message});

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

class _ChangelogItem extends StatelessWidget {
  const _ChangelogItem({
    required this.date,
    required this.title,
    required this.description,
  });

  final String date;
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_outlined, color: AppTheme.mint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
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
