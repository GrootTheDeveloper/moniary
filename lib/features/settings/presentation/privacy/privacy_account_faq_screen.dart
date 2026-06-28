import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class PrivacyAccountFaqScreen extends StatelessWidget {
  const PrivacyAccountFaqScreen({super.key});

  static const routePath = '/privacy-account-faq';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyFaq)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _FaqHero(),
            const SizedBox(height: 16),
            _FaqItem(
              question: context.l10n.privacyFaqStoredDataQuestion,
              answer: context.l10n.privacyFaqStoredDataAnswer,
            ),
            _FaqItem(
              question: context.l10n.privacyFaqExportBeforeDeletionQuestion,
              answer: context.l10n.privacyFaqExportBeforeDeletionAnswer,
            ),
            _FaqItem(
              question: context.l10n.privacyFaqDeletionImagesQuestion,
              answer: context.l10n.privacyFaqDeletionImagesAnswer,
            ),
            _FaqItem(
              question: context.l10n.privacyFaqDeletionFailQuestion,
              answer: context.l10n.privacyFaqDeletionFailAnswer,
            ),
            _FaqItem(
              question: context.l10n.privacyFaqExportLocationQuestion,
              answer: context.l10n.privacyFaqExportLocationAnswer,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqHero extends StatelessWidget {
  const _FaqHero();

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
        context.l10n.privacyFaqHeroBody,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

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
          Text(question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
