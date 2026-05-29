import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class PolicyChangelogScreen extends StatelessWidget {
  const PolicyChangelogScreen({super.key});

  static const routePath = '/policy-changelog';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalPolicyChangelog)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _ChangelogHero(),
            SizedBox(height: 16),
            _ChangelogItem(
              date: '27/05/2026',
              title: 'Bổ sung Legal & Policy Center',
              description:
                  'Thêm chính sách lưu giữ dữ liệu, thông báo dịch vụ bên thứ ba, miễn trừ tài chính và lịch sử thay đổi chính sách.',
            ),
            _ChangelogItem(
              date: '26/05/2026',
              title: 'Bổ sung Privacy Requests & Support',
              description:
                  'Thêm loại yêu cầu privacy, mẫu nội dung, preview, lịch sử request, trạng thái và timeline phản hồi.',
            ),
            _ChangelogItem(
              date: '26/05/2026',
              title: 'Bổ sung Store Readiness & Trust',
              description:
                  'Thêm About, Terms of Use, license entry, version/build info, checklist phát hành và liên hệ pháp lý.',
            ),
            _ChangelogItem(
              date: '25/05/2026',
              title: 'Khởi tạo chính sách MVP',
              description:
                  'Thêm privacy policy, data safety, data deletion policy, export dữ liệu và xóa tài khoản.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangelogHero extends StatelessWidget {
  const _ChangelogHero();

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
        'Lịch sử này giúp người dùng biết các nội dung privacy, legal và store readiness đã thay đổi khi nào.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  const _ChangelogItem({
    required this.date,
    required this.title,
    required this.description,
  });

  final String date;
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_outlined, color: AppTheme.mint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
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
