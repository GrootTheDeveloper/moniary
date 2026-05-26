import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class PermissionRationaleScreen extends StatelessWidget {
  const PermissionRationaleScreen({super.key});

  static const routePath = '/permission-rationale';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quyền truy cập')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _PermissionCard(
              icon: Icons.wifi_rounded,
              title: 'Internet',
              status: 'Cần thiết',
              description: 'Dùng để đăng nhập, đồng bộ Supabase Database và tải ảnh giao dịch từ Storage.',
            ),
            _PermissionCard(
              icon: Icons.camera_alt_outlined,
              title: 'Camera',
              status: 'Chỉ hỏi khi người dùng chụp ảnh',
              description: 'Dùng để chụp hóa đơn hoặc hình ảnh liên quan đến giao dịch.',
            ),
            _PermissionCard(
              icon: Icons.photo_library_outlined,
              title: 'Photo Picker',
              status: 'Chỉ mở khi người dùng chọn ảnh',
              description: 'Dùng Android Photo Picker để chọn ảnh mà không cần đọc toàn bộ thư viện.',
            ),
            _PermissionCard(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              status: 'Chỉ dùng khi bật nhắc nhở',
              description: 'MVP hiện không bắt buộc quyền này nếu chưa triển khai reminder production.',
            ),
            _PermissionCard(
              icon: Icons.block_rounded,
              title: 'Không dùng Location, Contacts, SMS',
              status: 'Không khai báo trong MVP',
              description: 'Moniary không cần vị trí, danh bạ hoặc SMS để ghi chi tiêu bằng ảnh.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String status;
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.amber, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(status, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
