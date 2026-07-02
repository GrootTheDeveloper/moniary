import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class ThirdPartyServicesScreen extends StatelessWidget {
  const ThirdPartyServicesScreen({super.key});

  static const routePath = '/third-party-services';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalThirdPartyServices)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ThirdPartyHero(),
            const SizedBox(height: 16),
            _ServiceItem(
              icon: Icons.cloud_queue_outlined,
              title: context.l10n.thirdPartyServicesSyncTitle,
              description: context.l10n.thirdPartyServicesSyncDesc,
            ),
            _ServiceItem(
              icon: Icons.flutter_dash_outlined,
              title: context.l10n.thirdPartyServicesAppPlatformTitle,
              description: context.l10n.thirdPartyServicesAppPlatformDesc,
            ),
            _ServiceItem(
              icon: Icons.folder_special_outlined,
              title: context.l10n.thirdPartyServicesDeviceStorageTitle,
              description: context.l10n.thirdPartyServicesDeviceStorageDesc,
            ),
            _ServiceItem(
              icon: Icons.no_accounts_outlined,
              title: context.l10n.thirdPartyServicesNoAdsTitle,
              description: context.l10n.thirdPartyServicesNoAdsDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThirdPartyHero extends StatelessWidget {
  const _ThirdPartyHero();

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
        context.l10n.thirdPartyServicesHero,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
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
