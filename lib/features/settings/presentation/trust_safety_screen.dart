import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class TrustSafetyScreen extends StatelessWidget {
  const TrustSafetyScreen({super.key});

  static const routePath = '/trust-safety';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin cậy & an toàn')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _TrustHero(),
            SizedBox(height: 16),
            _TrustNote(
              icon: Icons.account_balance_outlined,
              title: 'Không phải tư vấn tài chính',
              description:
                  'Moniary chỉ giúp ghi chép và xem lại dữ liệu thu chi cá nhân. App không đưa ra lời khuyên đầu tư, thuế hoặc kế toán.',
            ),
            _TrustNote(
              icon: Icons.edit_note_outlined,
              title: 'Dữ liệu do người dùng nhập',
              description:
                  'Số tiền, ghi chú, danh mục và ảnh giao dịch phụ thuộc vào dữ liệu người dùng tạo trong app.',
            ),
            _TrustNote(
              icon: Icons.visibility_off_outlined,
              title: 'Không thu thập ngoài phạm vi',
              description:
                  'MVP không đọc danh bạ, SMS, email inbox, vị trí hoặc tài khoản ngân hàng tự động.',
            ),
            _TrustNote(
              icon: Icons.ios_share_outlined,
              title: 'Cẩn thận khi chia sẻ file',
              description:
                  'File export có thể chứa dữ liệu tài chính cá nhân. Chỉ chia sẻ với người hoặc kênh hỗ trợ đáng tin cậy.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustHero extends StatelessWidget {
  const _TrustHero();

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
        'Các ghi chú này giúp người dùng hiểu rõ app làm gì, không làm gì và nên bảo vệ dữ liệu tài chính cá nhân ra sao.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({
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
