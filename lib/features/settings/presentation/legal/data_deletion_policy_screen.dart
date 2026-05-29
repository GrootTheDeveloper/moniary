import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class DataDeletionPolicyScreen extends StatelessWidget {
  const DataDeletionPolicyScreen({super.key});

  static const routePath = '/data-deletion-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalDataDeletionPolicy)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _PolicyStep(
              number: '1',
              title: 'Trước khi xóa',
              description:
                  'Người dùng có thể xuất CSV để giữ lại lịch sử giao dịch cá nhân.',
            ),
            _PolicyStep(
              number: '2',
              title: 'Dữ liệu sẽ bị xóa',
              description:
                  'Hồ sơ, ví, danh mục, giao dịch, thiết lập nhắc nhở và ảnh trong Storage thuộc user ID hiện tại.',
            ),
            _PolicyStep(
              number: '3',
              title: 'Cách xóa',
              description:
                  'App gọi Edge Function delete-account. Function xác thực session, xóa ảnh giao dịch rồi xóa Auth user.',
            ),
            _PolicyStep(
              number: '4',
              title: 'Dữ liệu ngoài app',
              description:
                  'Nếu cần xóa dữ liệu backup, log hoặc yêu cầu ngoài app, người dùng có thể liên hệ qua kênh privacy support của team.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyStep extends StatelessWidget {
  const _PolicyStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
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
          CircleAvatar(
            radius: 21,
            backgroundColor: AppTheme.danger.withValues(alpha: 0.16),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
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
