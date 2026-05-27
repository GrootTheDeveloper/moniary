import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import 'deletion_request_screen.dart';
import '../export/export_data_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class DeleteAccountHelpScreen extends StatelessWidget {
  const DeleteAccountHelpScreen({super.key});

  static const routePath = '/delete-account-help';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ xóa tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _DeleteHelpHero(),
            const SizedBox(height: 16),
            const _DeleteHelpStep(
              title: '1. Xuất dữ liệu trước khi xóa',
              description:
                  'Sau khi xóa tài khoản, dữ liệu app gắn với user hiện tại có thể không khôi phục được. Hãy export CSV, Excel hoặc PDF trước nếu cần giữ bản sao.',
            ),
            const _DeleteHelpStep(
              title: '2. Kiểm tra ảnh giao dịch',
              description:
                  'Ảnh giao dịch được xử lý cùng dữ liệu tài khoản. Hãy tải hoặc lưu lại file cần thiết trước khi xóa.',
            ),
            const _DeleteHelpStep(
              title: '3. Xác nhận kỹ trong app',
              description:
                  'Luồng xóa tài khoản yêu cầu xác nhận mạnh để tránh thao tác nhầm.',
            ),
            const _DeleteHelpStep(
              title: '4. Dùng fallback nếu xóa thất bại',
              description:
                  'Nếu thao tác trực tiếp lỗi, tạo file yêu cầu xóa dữ liệu thủ công và gửi kèm mô tả lỗi cho kênh hỗ trợ.',
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportDataScreen.routePath),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Xuất dữ liệu trước'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(DeletionRequestScreen.routePath),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Tạo request xóa dữ liệu'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(PrivacyContactScreen.routePath),
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Liên hệ privacy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteHelpHero extends StatelessWidget {
  const _DeleteHelpHero();

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
        'Xóa tài khoản là thao tác quan trọng. Hướng dẫn này giúp người dùng chuẩn bị dữ liệu và biết cách gửi yêu cầu hỗ trợ khi cần.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DeleteHelpStep extends StatelessWidget {
  const _DeleteHelpStep({required this.title, required this.description});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
