import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const routePath = '/terms-of-use';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalTermsOfUse)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _TermsHero(),
            const SizedBox(height: 16),
            _TermSection(
              title: context.l10n.termsOfUseScopeTitle,
              body: context.l10n.termsOfUseScopeDesc,
            ),
            _TermSection(
              title: context.l10n.termsOfUseAccountTitle,
              body: context.l10n.termsOfUseAccountDesc,
            ),
            _TermSection(
              title: context.l10n.termsOfUseContentTitle,
              body: context.l10n.termsOfUseContentDesc,
            ),
            _TermSection(
              title: context.l10n.termsOfUseLiabilityTitle,
              body: context.l10n.termsOfUseLiabilityDesc,
            ),
            _TermSection(
              title: context.l10n.termsOfUseChangesTitle,
              body: context.l10n.termsOfUseChangesDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsHero extends StatelessWidget {
  const _TermsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_outlined, color: AppTheme.mint, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.termsOfUseHeroDesc,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({required this.title, required this.body});

  final String title;
  final String body;

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
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
