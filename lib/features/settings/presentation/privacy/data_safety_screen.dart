import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class DataSafetyScreen extends StatelessWidget {
  const DataSafetyScreen({super.key});

  static const routePath = '/data-safety';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyDataSafety)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _DataSafetyCard(
              icon: Icons.person_outlined,
              title: context.l10n.dataSafetyPersonalInfoTitle,
              status: context.l10n.dataSafetyPersonalInfoStatus,
              description: context.l10n.dataSafetyPersonalInfoDesc,
            ),
            _DataSafetyCard(
              icon: Icons.account_balance_wallet_outlined,
              title: context.l10n.dataSafetyFinancialInfoTitle,
              status: context.l10n.dataSafetyFinancialInfoStatus,
              description: context.l10n.dataSafetyFinancialInfoDesc,
            ),
            _DataSafetyCard(
              icon: Icons.photo_camera_outlined,
              title: context.l10n.dataSafetyPhotosTitle,
              status: context.l10n.dataSafetyPhotosStatus,
              description: context.l10n.dataSafetyPhotosDesc,
            ),
            _DataSafetyCard(
              icon: Icons.fingerprint_outlined,
              title: context.l10n.dataSafetyUserIdTitle,
              status: context.l10n.dataSafetyUserIdStatus,
              description: context.l10n.dataSafetyUserIdDesc,
            ),
            _DataSafetyCard(
              icon: Icons.location_off_outlined,
              title: context.l10n.dataSafetyLocationTitle,
              status: context.l10n.dataSafetyLocationStatus,
              description: context.l10n.dataSafetyLocationDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSafetyCard extends StatelessWidget {
  const _DataSafetyCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String status;
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(status, style: Theme.of(context).textTheme.bodyLarge),
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
