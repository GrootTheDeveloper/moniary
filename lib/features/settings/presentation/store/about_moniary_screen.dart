import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/store/app_release_info.dart';

class AboutMoniaryScreen extends StatelessWidget {
  const AboutMoniaryScreen({super.key});

  static const routePath = '/about-moniary';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu Moniary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _AboutHero(),
            SizedBox(height: 16),
            _BuildInfoCard(),
            SizedBox(height: 12),
            _LicenseEntry(),
            SizedBox(height: 12),
            _AboutTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Mục đích',
              description:
                  'Moniary giúp người dùng ghi lại thu chi cá nhân, quản lý ví, danh mục và ảnh giao dịch trong một trải nghiệm đơn giản.',
            ),
            _AboutTile(
              icon: Icons.lock_outline_rounded,
              title: 'Định hướng dữ liệu',
              description:
                  'Dữ liệu tài chính thuộc về người dùng. App cung cấp công cụ xuất dữ liệu, xóa tài khoản và liên hệ privacy khi cần hỗ trợ.',
            ),
            _AboutTile(
              icon: Icons.verified_user_outlined,
              title: 'Trạng thái MVP',
              description:
                  'Phiên bản hiện tại tập trung vào ghi chép chi tiêu, minh bạch dữ liệu và các yêu cầu cần thiết để chuẩn bị phát hành Store.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseEntry extends StatelessWidget {
  const _LicenseEntry();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showLicensePage(
          context: context,
          applicationName: 'Moniary',
          applicationLegalese: 'MVP build for personal finance tracking.',
        );
      },
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
              child: const Icon(
                Icons.article_outlined,
                color: AppTheme.mint,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giấy phép mã nguồn mở',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Xem license của Flutter và các package đang dùng trong app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

class _BuildInfoCard extends StatelessWidget {
  const _BuildInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          _BuildInfoRow(label: 'Phiên bản', value: appReleaseInfo.version),
          const Divider(height: 24),
          _BuildInfoRow(label: 'Build', value: appReleaseInfo.buildNumber),
          const Divider(height: 24),
          _BuildInfoRow(
            label: 'Kênh phát hành',
            value: appReleaseInfo.releaseChannel,
          ),
        ],
      ),
    );
  }
}

class _BuildInfoRow extends StatelessWidget {
  const _BuildInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              color: AppTheme.mint,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text('Moniary', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Sổ tay thu chi cá nhân có kiểm soát dữ liệu rõ ràng cho người dùng.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
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
