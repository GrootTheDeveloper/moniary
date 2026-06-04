import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';

class FinancialDisclaimerScreen extends StatelessWidget {
  const FinancialDisclaimerScreen({super.key});

  static const routePath = '/financial-disclaimer';

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.trending_up_outlined,
        title: context.l10n.financialDisclaimerInvestmentTitle,
        description: context.l10n.financialDisclaimerInvestmentDesc,
      ),
      (
        icon: Icons.receipt_long_outlined,
        title: context.l10n.financialDisclaimerTaxTitle,
        description: context.l10n.financialDisclaimerTaxDesc,
      ),
      (
        icon: Icons.calculate_outlined,
        title: context.l10n.financialDisclaimerReferenceTitle,
        description: context.l10n.financialDisclaimerReferenceDesc,
      ),
      (
        icon: Icons.person_search_outlined,
        title: context.l10n.financialDisclaimerExpertTitle,
        description: context.l10n.financialDisclaimerExpertDesc,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.financialDisclaimerTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _DisclaimerHero(message: context.l10n.financialDisclaimerSubtitle),
            const SizedBox(height: 16),
            ...items.map(
              (item) => _DisclaimerItem(
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

class _DisclaimerHero extends StatelessWidget {
  const _DisclaimerHero({required this.message});

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

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem({
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
