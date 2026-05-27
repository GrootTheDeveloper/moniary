import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class PrivacyAccountFaqScreen extends StatelessWidget {
  const PrivacyAccountFaqScreen({super.key});

  static const routePath = '/privacy-account-faq';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ privacy & tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _FaqHero(),
            SizedBox(height: 16),
            _FaqItem(
              question: 'Moniary lưu những dữ liệu nào?',
              answer:
                  'App lưu hồ sơ, ví, danh mục, giao dịch, ghi chú và đường dẫn ảnh giao dịch khi người dùng tạo dữ liệu trong app.',
            ),
            _FaqItem(
              question:
                  'Tôi có thể xuất dữ liệu trước khi xóa tài khoản không?',
              answer:
                  'Có. Bạn có thể xuất dữ liệu thành CSV, Excel hoặc PDF trong phần Xuất dữ liệu của tôi.',
            ),
            _FaqItem(
              question: 'Xóa tài khoản có xóa ảnh giao dịch không?',
              answer:
                  'Luồng xóa tài khoản được thiết kế để xóa dữ liệu app và ảnh giao dịch gắn với user hiện tại.',
            ),
            _FaqItem(
              question: 'Nếu xóa tài khoản trực tiếp thất bại thì sao?',
              answer:
                  'Bạn có thể tạo file yêu cầu xóa dữ liệu thủ công và gửi cho kênh hỗ trợ privacy.',
            ),
            _FaqItem(
              question: 'File export nằm ở đâu?',
              answer:
                  'File export được lưu trong thư mục tài liệu của app trên thiết bị và có thể mở/chia sẻ từ lịch sử export.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqHero extends StatelessWidget {
  const _FaqHero();

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
        'Các câu hỏi thường gặp về dữ liệu cá nhân, export, xóa tài khoản và yêu cầu privacy.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

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
          Text(question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
