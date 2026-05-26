import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        Text(
          'Tổng quan dữ liệu',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
        Text(
          'Nhóm dữ liệu đang lưu',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _InventoryTile(
          icon: Icons.person_outline_rounded,
          title: 'Hồ sơ tài khoản',
          description:
              'Tên hiển thị, email, avatar, timezone và trạng thái đăng nhập.',
        ),
        const _InventoryTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Ví',
          description:
              'Tên ví, loại ví, số dư ban đầu, trạng thái mặc định và hiển thị.',
        ),
        const _InventoryTile(
          icon: Icons.category_outlined,
          title: 'Danh mục',
          description:
              'Tên danh mục, loại thu/chi, trạng thái mặc định và hiển thị.',
        ),
        const _InventoryTile(
          icon: Icons.receipt_long_outlined,
          title: 'Giao dịch',
          description:
              'Số tiền, loại giao dịch, ví, danh mục, ghi chú và ngày giờ.',
        ),
        const _InventoryTile(
          icon: Icons.image_outlined,
          title: 'Ảnh giao dịch',
          description:
              'Đường dẫn ảnh trong Storage private bucket, hiển thị qua signed URL.',
        ),
        const _InventoryTile(
          icon: Icons.notifications_none_rounded,
          title: 'Thiết lập nhắc nhở',
          description:
              'Các tùy chọn nhắc ghi chi tiêu khi tính năng reminder được bật.',
        ),
        const SizedBox(height: 22),
        Text('Dữ liệu ảnh', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _PhotoSummaryCard(summary: summary),
        const SizedBox(height: 22),
        Text('Độ mới dữ liệu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _FreshnessCard(summary: summary),
        const SizedBox(height: 22),
        Text(
          'Lưu ý dữ liệu nhạy cảm',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _SensitiveDataNotice(),
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
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: AppTheme.mint),
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

class _PhotoSummaryCard extends StatelessWidget {
  const _PhotoSummaryCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.transactionCount == 0 ? 1 : summary.transactionCount;
    final ratio = summary.photoTransactionCount / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ảnh giao dịch', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            color: AppTheme.mint,
            backgroundColor: AppTheme.outline,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PhotoCount(
                  label: 'Có ảnh',
                  value: summary.photoTransactionCount.toString(),
                ),
              ),
              Expanded(
                child: _PhotoCount(
                  label: 'Không ảnh',
                  value: summary.transactionWithoutPhotoCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FreshnessCard extends StatelessWidget {
  const _FreshnessCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'vi_VN');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          _FreshnessRow(
            icon: Icons.history_rounded,
            label: 'Giao dịch cũ nhất',
            value: _formatDate(summary.oldestTransactionDate, dateFormat),
          ),
          const Divider(height: 24),
          _FreshnessRow(
            icon: Icons.update_rounded,
            label: 'Giao dịch mới nhất',
            value: _formatDate(summary.newestTransactionDate, dateFormat),
          ),
          const Divider(height: 24),
          _FreshnessRow(
            icon: Icons.file_download_done_outlined,
            label: 'Lần xuất dữ liệu gần nhất',
            value: _formatDate(summary.latestExportDate, dateTimeFormat),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value, DateFormat format) {
    if (value == null) {
      return 'Chưa có dữ liệu';
    }
    return format.format(value.toLocal());
  }
}

class _FreshnessRow extends StatelessWidget {
  const _FreshnessRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class _SensitiveDataNotice extends StatelessWidget {
  const _SensitiveDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppTheme.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dữ liệu tài chính có thể gồm số tiền, ghi chú, ảnh hóa đơn và file đã xuất. Chỉ chia sẻ file export với người bạn tin cậy và xóa file cục bộ khi không còn cần dùng.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
