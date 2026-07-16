import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../privacy/privacy_contact_screen.dart';

class LegalContactScreen extends StatelessWidget {
  const LegalContactScreen({super.key});

  static const routePath = '/legal-contact';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalContact)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _LegalHero(),
            const SizedBox(height: 16),
            _ContactCard(
              icon: Icons.privacy_tip_outlined,
              title: context.l10n.legalContactPrivacy,
              description: context.l10n.legalContactPrivacyDesc,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            _ContactCard(
              icon: Icons.support_agent_outlined,
              title: context.l10n.legalContactSupport,
              description: context.l10n.legalContactSupportDesc,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            _ContactCard(
              icon: Icons.gavel_outlined,
              title: context.l10n.legalContactLegal,
              description: context.l10n.legalContactLegalDesc,
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () => context.push(PrivacyContactScreen.routePath),
              icon: const Icon(Icons.lock_person_outlined),
              label: Text(context.l10n.legalOpenRequestCenter),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalHero extends StatelessWidget {
  const _LegalHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.legalContactHero,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.privacyInAppChannelDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surface,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.mint),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
