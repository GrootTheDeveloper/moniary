import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';

import '../../../../app/app_theme.dart';

class DataRetentionPolicyScreen extends StatelessWidget {
  const DataRetentionPolicyScreen({super.key});

  static const routePath = '/data-retention-policy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalDataRetention)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _RetentionHero(),
            SizedBox(height: 16),
            _RetentionItem(
              icon: Icons.cloud_outlined,
              title: 'Dữ liệu trên cloud',
              description:
                  'Hồ sơ, ví, danh mục, giao dịch và đường dẫn ảnh giao dịch được giữ khi tài khoản còn hoạt động để app có thể đồng bộ và hiển thị lại dữ liệu.',
            ),
            _RetentionItem(
              icon: Icons.photo_library_outlined,
              title: 'Ảnh giao dịch',
              description:
                  'Ảnh giao dịch chỉ được lưu khi người dùng chủ động chụp hoặc chọn ảnh. Ảnh sẽ được xử lý cùng dữ liệu tài khoản khi xóa tài khoản.',
            ),
            _RetentionItem(
              icon: Icons.folder_outlined,
              title: 'File cục bộ',
              description:
                  'File export và lịch sử request được tạo trên thiết bị. Người dùng có thể tự quản lý, chia sẻ hoặc xóa các file này khỏi bộ nhớ cục bộ.',
            ),
            _RetentionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Sau khi xóa tài khoản',
              description:
                  'Moniary gọi luồng xóa tài khoản để gỡ dữ liệu app gắn với user hiện tại. Nếu thao tác thất bại, người dùng có thể tạo request xóa dữ liệu thủ công.',
            ),
          ],
        ),
      ),
    );
  }
}

class _RetentionHero extends StatelessWidget {
  const _RetentionHero();

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
        'Chính sách này giải thích dữ liệu nào được giữ trong tài khoản, dữ liệu nào nằm trên thiết bị và cách người dùng có thể xóa hoặc xuất dữ liệu.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _RetentionItem extends StatelessWidget {
  const _RetentionItem({
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
        ],
      ),
    );
  }
}
