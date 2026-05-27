import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import 'help_center_screen.dart';
import 'privacy_contact_screen.dart';

class SupportRequestChecklistScreen extends StatelessWidget {
  const SupportRequestChecklistScreen({super.key});

  static const routePath = '/support-request-checklist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist gửi hỗ trợ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ChecklistHero(),
            const SizedBox(height: 16),
            const _ChecklistItem(
              title: 'Mô tả thao tác đã làm',
              description:
                  'Ghi rõ bạn đang export, xóa tài khoản, tạo request hay mở file nào.',
            ),
            const _ChecklistItem(
              title: 'Thêm thông báo lỗi nếu có',
              description:
                  'Copy nội dung lỗi hoặc mô tả màn hình đang hiển thị để team dễ kiểm tra.',
            ),
            const _ChecklistItem(
              title: 'Đính kèm file request/export khi phù hợp',
              description:
                  'Nếu là yêu cầu privacy hoặc xóa dữ liệu thủ công, gửi kèm file JSON đã tạo.',
            ),
            const _ChecklistItem(
              title: 'Copy diagnostic info',
              description:
                  'Gửi kèm version, build và kênh release từ Trung tâm trợ giúp.',
            ),
            const _ChecklistItem(
              title: 'Không gửi dữ liệu quá nhạy cảm',
              description:
                  'Không gửi mật khẩu, access token hoặc ảnh hóa đơn nhạy cảm nếu không thật sự cần thiết.',
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(HelpCenterScreen.routePath),
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text('Mở trung tâm trợ giúp'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => context.push(PrivacyContactScreen.routePath),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Tạo yêu cầu hỗ trợ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistHero extends StatelessWidget {
  const _ChecklistHero();

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
        'Chuẩn bị đủ thông tin trước khi gửi yêu cầu giúp team hỗ trợ nhanh hơn và tránh chia sẻ dữ liệu nhạy cảm không cần thiết.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.title, required this.description});

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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppTheme.success,
              size: 20,
            ),
          ),
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
