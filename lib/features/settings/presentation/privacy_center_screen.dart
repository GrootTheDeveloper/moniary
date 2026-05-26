import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import 'data_safety_screen.dart';
import 'permission_rationale_screen.dart';
import 'privacy_policy_screen.dart';

class PrivacyCenterScreen extends StatelessWidget {
  const PrivacyCenterScreen({super.key});

  static const routePath = '/privacy-center';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm riêng tư')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _PrivacyHero(),
            const SizedBox(height: 18),
            _PrivacyActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Chính sách bảo mật',
              subtitle: 'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.',
              onTap: () => context.push(PrivacyPolicyScreen.routePath),
            ),
            const SizedBox(height: 12),
            _PrivacyActionTile(
              icon: Icons.verified_user_outlined,
              title: 'Data Safety',
              subtitle: 'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong MVP.',
              onTap: () => context.push(DataSafetyScreen.routePath),
            ),
            const SizedBox(height: 12),
            _PrivacyActionTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Quyền truy cập',
              subtitle: 'Giải thích lý do Moniary dùng hoặc không dùng từng quyền Android.',
              onTap: () => context.push(PermissionRationaleScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.mint),
          ),
          const SizedBox(height: 14),
          Text('Quyền riêng tư của bạn', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Quản lý các thông tin về dữ liệu, quyền truy cập và lựa chọn bảo mật trong Moniary.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PrivacyActionTile extends StatelessWidget {
  const _PrivacyActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mint),
          ],
        ),
      ),
    );
  }
}
