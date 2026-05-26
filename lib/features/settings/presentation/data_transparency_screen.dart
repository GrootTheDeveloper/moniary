import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../application/account_actions_controller.dart';
import '../domain/data_transparency_summary.dart';

class DataTransparencyScreen extends ConsumerWidget {
  const DataTransparencyScreen({super.key});

  static const routePath = '/data-transparency';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dataTransparencySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dữ liệu của tôi')),
      body: SafeArea(
        child: summaryAsync.when(
          data: (summary) => _Overview(summary: summary),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Tổng quan dữ liệu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _MetricGrid(
          items: [
            _MetricItem('Giao dịch', summary.transactionCount.toString()),
            _MetricItem('Ví', summary.walletCount.toString()),
            _MetricItem('Danh mục', summary.categoryCount.toString()),
            _MetricItem('Có ảnh', summary.photoTransactionCount.toString()),
          ],
        ),
        const SizedBox(height: 22),
        Text('Nhóm dữ liệu đang lưu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const _InventoryTile(
          icon: Icons.person_outline_rounded,
          title: 'Hồ sơ tài khoản',
          description: 'Tên hiển thị, email, avatar, timezone và trạng thái đăng nhập.',
        ),
        const _InventoryTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Ví',
          description: 'Tên ví, loại ví, số dư ban đầu, trạng thái mặc định và hiển thị.',
        ),
        const _InventoryTile(
          icon: Icons.category_outlined,
          title: 'Danh mục',
          description: 'Tên danh mục, loại thu/chi, trạng thái mặc định và hiển thị.',
        ),
        const _InventoryTile(
          icon: Icons.receipt_long_outlined,
          title: 'Giao dịch',
          description: 'Số tiền, loại giao dịch, ví, danh mục, ghi chú và ngày giờ.',
        ),
        const _InventoryTile(
          icon: Icons.image_outlined,
          title: 'Ảnh giao dịch',
          description: 'Đường dẫn ảnh trong Storage private bucket, hiển thị qua signed URL.',
        ),
        const _InventoryTile(
          icon: Icons.notifications_none_rounded,
          title: 'Thiết lập nhắc nhở',
          description: 'Các tùy chọn nhắc ghi chi tiêu khi tính năng reminder được bật.',
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.mint,
                    ),
              ),
              const SizedBox(height: 6),
              Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final String value;
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
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
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
