import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class PermissionRationaleScreen extends StatelessWidget {
  const PermissionRationaleScreen({super.key});

  static const routePath = '/permission-rationale';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyPermissionRationale)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _PermissionCard(
              icon: Icons.wifi_outlined,
              title: context.l10n.permissionInternetTitle,
              status: context.l10n.permissionInternetStatus,
              description: context.l10n.permissionInternetDesc,
            ),
            _PermissionCard(
              icon: Icons.camera_alt_outlined,
              title: context.l10n.permissionCameraTitle,
              status: context.l10n.permissionCameraStatus,
              description: context.l10n.permissionCameraDesc,
            ),
            _PermissionCard(
              icon: Icons.photo_library_outlined,
              title: context.l10n.permissionPhotoTitle,
              status: context.l10n.permissionPhotoStatus,
              description: context.l10n.permissionPhotoDesc,
            ),
            _PermissionCard(
              icon: Icons.notifications_none_outlined,
              title: context.l10n.permissionNotiTitle,
              status: context.l10n.permissionNotiStatus,
              description: context.l10n.permissionNotiDesc,
            ),
            _PermissionCard(
              icon: Icons.block_outlined,
              title: context.l10n.permissionLocationTitle,
              status: context.l10n.permissionLocationStatus,
              description: context.l10n.permissionLocationDesc,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
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
              color: AppTheme.amber.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.amber, size: 22),
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
