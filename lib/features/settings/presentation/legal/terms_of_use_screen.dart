import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const routePath = '/terms-of-use';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điều khoản sử dụng')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _TermsHero(),
            SizedBox(height: 16),
            _TermSection(
              title: '1. Phạm vi sử dụng',
              body:
                  'Moniary được cung cấp để người dùng ghi chép và tự quản lý dữ liệu thu chi cá nhân. Người dùng chịu trách nhiệm về độ chính xác của dữ liệu đã nhập.',
            ),
            _TermSection(
              title: '2. Dữ liệu tài khoản',
              body:
                  'Người dùng có thể xuất dữ liệu, gửi yêu cầu privacy và xóa tài khoản theo các công cụ được cung cấp trong app.',
            ),
            _TermSection(
              title: '3. Nội dung người dùng',
              body:
                  'Ghi chú, số tiền và ảnh giao dịch do người dùng nhập hoặc tải lên chỉ nên phục vụ mục đích quản lý chi tiêu cá nhân.',
            ),
            _TermSection(
              title: '4. Giới hạn trách nhiệm',
              body:
                  'Moniary không phải công cụ tư vấn tài chính, kế toán, thuế hoặc pháp lý. Các thống kê trong app chỉ có tính tham khảo.',
            ),
            _TermSection(
              title: '5. Thay đổi điều khoản',
              body:
                  'Điều khoản có thể được cập nhật khi app bổ sung tính năng hoặc chuẩn bị phát hành chính thức.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsHero extends StatelessWidget {
  const _TermsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_outlined, color: AppTheme.mint, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Các điều khoản này tóm tắt cách người dùng nên sử dụng Moniary trong phiên bản MVP.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  const _TermSection({required this.title, required this.body});

  final String title;
  final String body;

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
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
