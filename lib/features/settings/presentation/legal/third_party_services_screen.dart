import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class ThirdPartyServicesScreen extends StatelessWidget {
  const ThirdPartyServicesScreen({super.key});

  static const routePath = '/third-party-services';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dịch vụ bên thứ ba')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _ThirdPartyHero(),
            SizedBox(height: 16),
            _ServiceItem(
              icon: Icons.cloud_queue_outlined,
              title: 'Supabase',
              description:
                  'Được dùng cho đăng nhập, cơ sở dữ liệu, storage ảnh giao dịch và edge function xóa tài khoản.',
            ),
            _ServiceItem(
              icon: Icons.flutter_dash_outlined,
              title: 'Flutter',
              description:
                  'Framework giao diện chính của app, kèm các package hỗ trợ điều hướng, trạng thái, camera, chọn ảnh và xử lý file.',
            ),
            _ServiceItem(
              icon: Icons.folder_special_outlined,
              title: 'Bộ nhớ thiết bị',
              description:
                  'File export, request privacy và lịch sử export/request được ghi trong thư mục tài liệu của app trên thiết bị.',
            ),
            _ServiceItem(
              icon: Icons.no_accounts_outlined,
              title: 'Không tích hợp quảng cáo',
              description:
                  'MVP không dùng SDK quảng cáo, tracking marketing, danh bạ, SMS, email inbox hoặc kết nối ngân hàng tự động.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ThirdPartyHero extends StatelessWidget {
  const _ThirdPartyHero();

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
        'Thông báo này giúp người dùng hiểu app dựa vào dịch vụ nào để đăng nhập, lưu trữ và vận hành dữ liệu.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
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
