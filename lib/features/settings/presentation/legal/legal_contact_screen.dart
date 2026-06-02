import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

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
              title: 'Privacy',
              value: AppConstants.privacyEmail,
              description: context.l10n.legalContactPrivacyDesc,
            ),
            _ContactCard(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              value: AppConstants.supportEmail,
              description: context.l10n.legalContactSupportDesc,
            ),
            _ContactCard(
              icon: Icons.gavel_outlined,
              title: 'Legal',
              value: AppConstants.legalEmail,
              description: context.l10n.legalContactLegalDesc,
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () => _copyAll(context),
              icon: const Icon(Icons.content_copy_outlined),
              label: Text(context.l10n.legalCopyAllContacts),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Privacy: ${AppConstants.privacyEmail}\nSupport: ${AppConstants.supportEmail}\nLegal: ${AppConstants.legalEmail}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.legalCopyContactSuccess)),
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
      child: Text(
        context.l10n.legalContactHero,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
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
          Row(
            children: [
              Icon(icon, color: AppTheme.mint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã copy $value')));
  }
}
