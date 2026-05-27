import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';

class DataSafetyScreen extends StatelessWidget {
  const DataSafetyScreen({super.key});

  static const routePath = '/data-safety';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Safety')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            _DataSafetyCard(
              icon: Icons.person_outline_rounded,
              title: 'Personal info',
              status: 'Có, khi đăng nhập email hoặc Google',
              description:
                  'Tên hiển thị, email, avatar và user ID dùng cho đăng nhập và đồng bộ dữ liệu.',
            ),
            _DataSafetyCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financial info',
              status: 'Có',
              description:
                  'Ví, danh mục, số tiền, ghi chú và ngày giao dịch do người dùng nhập.',
            ),
            _DataSafetyCard(
              icon: Icons.photo_camera_outlined,
              title: 'Photos',
              status: 'Có, khi người dùng chủ động chọn/chụp',
              description:
                  'Ảnh giao dịch được lưu trong private storage và chỉ hiển thị qua signed URL.',
            ),
            _DataSafetyCard(
              icon: Icons.fingerprint_rounded,
              title: 'User ID',
              status: 'Có',
              description:
                  'Dùng để gắn dữ liệu với đúng tài khoản và áp dụng RLS trên Supabase.',
            ),
            _DataSafetyCard(
              icon: Icons.location_off_outlined,
              title: 'Location, Contacts, SMS',
              status: 'Không thu thập trong MVP',
              description:
                  'Moniary không xin quyền vị trí, danh bạ hoặc đọc SMS/email để import giao dịch.',
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSafetyCard extends StatelessWidget {
  const _DataSafetyCard({
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
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 22),
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
