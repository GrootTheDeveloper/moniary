import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import 'export_data_screen.dart';
import 'export_history_screen.dart';
import '../privacy/privacy_contact_screen.dart';

class ExportTroubleshootingScreen extends StatelessWidget {
  const ExportTroubleshootingScreen({super.key});

  static const routePath = '/export-troubleshooting';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ export dữ liệu')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _ExportHelpHero(),
            const SizedBox(height: 16),
            const _TroubleshootingStep(
              title: '1. Kiểm tra loại dữ liệu đã chọn',
              description:
                  'Nếu file trống, hãy kiểm tra bạn đã chọn Giao dịch, Ví hoặc Danh mục trong bộ lọc export.',
            ),
            const _TroubleshootingStep(
              title: '2. Kiểm tra khoảng ngày',
              description:
                  'Nếu chọn khoảng ngày quá hẹp, file có thể không có giao dịch phù hợp.',
            ),
            const _TroubleshootingStep(
              title: '3. Mở lại từ lịch sử export',
              description:
                  'Sau khi tạo file, vào lịch sử export để mở lại đường dẫn file và chia sẻ khi cần.',
            ),
            const _TroubleshootingStep(
              title: '4. Tạo request hỗ trợ',
              description:
                  'Nếu file không tạo được hoặc không mở được, hãy tạo request privacy/support kèm mô tả lỗi.',
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportDataScreen.routePath),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Mở export dữ liệu'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(ExportHistoryScreen.routePath),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Mở lịch sử export'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
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

class _ExportHelpHero extends StatelessWidget {
  const _ExportHelpHero();

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
        'Hướng dẫn này giúp xử lý nhanh khi file CSV, Excel hoặc PDF không có dữ liệu, không mở được hoặc không tìm thấy sau khi export.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _TroubleshootingStep extends StatelessWidget {
  const _TroubleshootingStep({required this.title, required this.description});

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
