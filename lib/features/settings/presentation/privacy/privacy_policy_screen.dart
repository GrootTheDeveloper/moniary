import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routePath = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyPolicyTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LeadCard(),
              const SizedBox(height: 18),
              _PolicySection(
                title: context.l10n.privacyPolicyDataTitle,
                items: [
                  context.l10n.privacyPolicyDataItem1,
                  context.l10n.privacyPolicyDataItem2,
                  context.l10n.privacyPolicyDataItem3,
                  context.l10n.privacyPolicyDataItem4,
                ],
              ),
              _PolicySection(
                title: context.l10n.privacyPolicyPurposeTitle,
                items: [
                  context.l10n.privacyPolicyPurposeItem1,
                  context.l10n.privacyPolicyPurposeItem2,
                  context.l10n.privacyPolicyPurposeItem3,
                  context.l10n.privacyPolicyPurposeItem4,
                ],
              ),
              _PolicySection(
                title: context.l10n.privacyPolicyShareTitle,
                items: [
                  context.l10n.privacyPolicyShareItem1,
                  context.l10n.privacyPolicyShareItem2,
                  context.l10n.privacyPolicyShareItem3,
                ],
              ),
              _PolicySection(
                title: context.l10n.privacyPolicyDeleteTitle,
                items: [
                  context.l10n.privacyPolicyDeleteItem1,
                  context.l10n.privacyPolicyDeleteItem2,
                  context.l10n.privacyPolicyDeleteItem3,
                ],
              ),
              _PolicySection(
                title: context.l10n.privacyPolicySafetyTitle,
                items: [
                  context.l10n.privacyPolicySafetyItem1,
                  context.l10n.privacyPolicySafetyItem2,
                  context.l10n.privacyPolicySafetyItem3,
                  context.l10n.privacyPolicySafetyItem4,
                ],
              ),
              const _ContactBox(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.privacyPolicyLeadTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.privacyPolicyLeadDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppTheme.mint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBox extends StatelessWidget {
  const _ContactBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        context.l10n.privacyPolicyContactDesc,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
