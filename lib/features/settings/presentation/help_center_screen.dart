import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import 'export_data_screen.dart';
import 'export_troubleshooting_screen.dart';
import 'privacy_account_faq_screen.dart';
import 'privacy_contact_screen.dart';
import 'user_rights_summary_screen.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const routePath = '/help-center';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm trợ giúp')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _HelpHero(),
            const SizedBox(height: 16),
            _HelpTopic(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & tài khoản',
              description:
                  'Xem quyền dữ liệu, yêu cầu privacy và các lựa chọn liên quan tài khoản.',
              onTap: () => context.push(PrivacyAccountFaqScreen.routePath),
            ),
            _HelpTopic(
              icon: Icons.assignment_ind_outlined,
              title: 'Quyền dữ liệu',
              description:
                  'Tóm tắt quyền xem, xuất, sửa/xóa dữ liệu và liên hệ privacy.',
              onTap: () => context.push(UserRightsSummaryScreen.routePath),
            ),
            _HelpTopic(
              icon: Icons.file_download_outlined,
              title: 'Xuất dữ liệu',
              description:
                  'Xử lý khi export CSV, Excel hoặc PDF lỗi, trống hoặc không tìm thấy file.',
              onTap: () => context.push(ExportTroubleshootingScreen.routePath),
            ),
            _HelpTopic(
              icon: Icons.download_done_outlined,
              title: 'Tạo file export',
              description:
                  'Mở luồng export khi cần tạo bản sao dữ liệu cá nhân.',
              onTap: () => context.push(ExportDataScreen.routePath),
            ),
            _HelpTopic(
              icon: Icons.support_agent_outlined,
              title: 'Liên hệ hỗ trợ',
              description:
                  'Tạo request privacy hoặc copy thông tin liên hệ để gửi cho team hỗ trợ.',
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

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
        'Tìm nhanh các hướng dẫn liên quan đến dữ liệu, quyền riêng tư, export và hỗ trợ tài khoản trong Moniary.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _HelpTopic extends StatelessWidget {
  const _HelpTopic({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mint),
          ],
        ),
      ),
    );
  }
}
