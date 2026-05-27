import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class FinancialDisclaimerScreen extends StatelessWidget {
  const FinancialDisclaimerScreen({super.key});

  static const routePath = '/financial-disclaimer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Miễn trừ tài chính')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _DisclaimerHero(),
            SizedBox(height: 16),
            _DisclaimerItem(
              icon: Icons.trending_up_outlined,
              title: 'Không phải tư vấn đầu tư',
              description:
                  'Moniary không đề xuất mua, bán, đầu tư hoặc phân bổ tài sản. Người dùng tự chịu trách nhiệm với quyết định tài chính của mình.',
            ),
            _DisclaimerItem(
              icon: Icons.receipt_long_outlined,
              title: 'Không phải tư vấn thuế/kế toán',
              description:
                  'Dữ liệu trong app không thay thế chứng từ, báo cáo kế toán hoặc tư vấn thuế chuyên nghiệp.',
            ),
            _DisclaimerItem(
              icon: Icons.calculate_outlined,
              title: 'Số liệu có tính tham khảo',
              description:
                  'Tổng thu, tổng chi và các file export phụ thuộc vào dữ liệu người dùng nhập, có thể sai nếu nhập thiếu hoặc nhập nhầm.',
            ),
            _DisclaimerItem(
              icon: Icons.person_search_outlined,
              title: 'Khi cần quyết định quan trọng',
              description:
                  'Người dùng nên kiểm tra lại dữ liệu gốc và hỏi chuyên gia phù hợp trước các quyết định tài chính, thuế hoặc pháp lý.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerHero extends StatelessWidget {
  const _DisclaimerHero();

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
        'Moniary là công cụ ghi chép thu chi cá nhân. App không thay thế lời khuyên chuyên môn về tài chính, kế toán, thuế hoặc pháp lý.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem({
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
          Icon(icon, color: AppTheme.amber),
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
