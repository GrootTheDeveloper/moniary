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
