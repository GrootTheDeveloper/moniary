import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class PrivacyContactScreen extends StatelessWidget {
  const PrivacyContactScreen({super.key});

  static const routePath = '/privacy-contact';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ quyền riêng tư')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _ContactHero(),
            SizedBox(height: 16),
            _ContactInfoTile(
              icon: Icons.email_outlined,
              title: 'Email hỗ trợ',
              value: 'privacy@moniary.app',
              description: 'Dùng cho yêu cầu xóa dữ liệu, xuất dữ liệu hoặc câu hỏi về quyền riêng tư.',
            ),
            _ContactInfoTile(
              icon: Icons.info_outline_rounded,
              title: 'Thông tin cần gửi',
              value: 'User ID hoặc email đăng nhập',
              description: 'Không gửi mật khẩu, access token, ảnh hóa đơn nhạy cảm hoặc số tiền chi tiết qua email.',
            ),
            _ContactInfoTile(
              icon: Icons.schedule_outlined,
              title: 'Thời gian phản hồi',
              value: 'Trong vòng 7 ngày làm việc',
              description: 'Team cần cập nhật thời gian thực tế trước khi phát hành production.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactHero extends StatelessWidget {
  const _ContactHero();

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
          const Icon(Icons.support_agent_rounded, color: AppTheme.mint, size: 34),
          const SizedBox(height: 12),
          Text('Yêu cầu về dữ liệu cá nhân', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Nếu không thể xử lý trực tiếp trong app, người dùng có thể liên hệ team để yêu cầu hỗ trợ về dữ liệu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  const _ContactInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
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
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
