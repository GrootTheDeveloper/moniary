import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class TrustSafetyScreen extends StatelessWidget {
  const TrustSafetyScreen({super.key});

  static const routePath = '/trust-safety';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.storeTrustSafety)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _TrustHero(),
            const SizedBox(height: 16),
            _TrustNote(
              icon: Icons.account_balance_outlined,
              title: context.l10n.notFinancialAdviceTitle,
              description: context.l10n.notFinancialAdviceDesc,
            ),
            _TrustNote(
              icon: Icons.edit_note_outlined,
              title: context.l10n.userEnteredDataTitle,
              description: context.l10n.userEnteredDataDesc,
            ),
            _TrustNote(
              icon: Icons.visibility_off_outlined,
              title: context.l10n.noOverCollectionTitle,
              description: context.l10n.noOverCollectionDesc,
            ),
            _TrustNote(
              icon: Icons.ios_share_outlined,
              title: context.l10n.carefulFileSharingTitle,
              description: context.l10n.carefulFileSharingDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustHero extends StatelessWidget {
  const _TrustHero();

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
        context.l10n.trustHeroText,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({
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
          Icon(icon, color: AppTheme.amber),
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
