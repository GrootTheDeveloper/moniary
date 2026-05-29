import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class StoreComplianceChecklistScreen extends StatelessWidget {
  const StoreComplianceChecklistScreen({super.key});

  static const routePath = '/store-compliance-checklist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.storeComplianceChecklist)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _ChecklistHero(),
            SizedBox(height: 16),
            _ChecklistItem(
              title: 'Chính sách bảo mật',
              description:
                  'Có màn privacy policy mô tả dữ liệu tài chính, ảnh giao dịch và cách xử lý dữ liệu.',
            ),
            _ChecklistItem(
              title: 'Xóa tài khoản',
              description:
                  'Có luồng xóa tài khoản trong app và fallback tạo request thủ công.',
            ),
            _ChecklistItem(
              title: 'Xuất dữ liệu',
              description:
                  'Người dùng có thể export dữ liệu CSV, Excel hoặc PDF trước khi rời app.',
            ),
            _ChecklistItem(
              title: 'Data Safety',
              description:
                  'Có phần tóm tắt nhóm dữ liệu được lưu và nhóm dữ liệu app không thu thập.',
            ),
            _ChecklistItem(
              title: 'Liên hệ privacy',
              description:
                  'Có kênh hỗ trợ, request history và trạng thái xử lý yêu cầu privacy.',
            ),
            _ChecklistItem(
              title: 'Điều khoản sử dụng',
              description:
                  'Có terms of use và ghi chú giới hạn trách nhiệm của app MVP.',
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
        'Các mục dưới đây giúp rà soát nhanh những phần người dùng và reviewer cần thấy trước khi app được phát hành.',
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
