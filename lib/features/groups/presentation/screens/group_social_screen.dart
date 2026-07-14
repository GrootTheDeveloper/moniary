import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';
import 'group_transaction_detail_screen.dart';

class GroupSocialScreen extends ConsumerWidget {
  const GroupSocialScreen({required this.groupId, super.key});

  static const routePath = '/groups/social';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social & Feed'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Album'),
              Tab(text: 'Summary'),
              Tab(text: 'Public'),
              Tab(text: 'Recurring'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FeedTab(groupId: groupId),
            _PhotoAlbumTab(groupId: groupId),
            _SummaryTab(groupId: groupId),
            _PublicProfileTab(groupId: groupId),
            _RecurringTab(groupId: groupId),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(groupFeedProvider(groupId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupFeedProvider(groupId)),
      child: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupFeedProvider(groupId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState(text: 'Chưa có bài đăng trong feed nhóm.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final transaction = item.transaction;
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push(
                    GroupTransactionDetailScreen.routePath,
                    extra: transaction.id,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppTheme.surfaceRaised,
                              child: Icon(Icons.person_outline),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.creatorName ?? 'Thành viên',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(transaction.transactionDate),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              ref.formatAmount(transaction.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (transaction.imagePath != null) ...[
                          const SizedBox(height: 12),
                          AspectRatio(
                            aspectRatio: 1.35,
                            child: SupabaseImage(
                              imagePath: transaction.imagePath,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          transaction.caption ??
                              transaction.categoryName ??
                              'Giao dịch nhóm',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...item.reactions.map(
                              (reaction) => Chip(
                                label: Text(
                                  '${reaction.emoji} ${reaction.count}',
                                ),
                              ),
                            ),
                            Chip(
                              avatar: const Icon(Icons.mode_comment_outlined),
                              label: Text('${item.commentCount} bình luận'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PhotoAlbumTab extends ConsumerWidget {
  const _PhotoAlbumTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(groupPhotoAlbumProvider(groupId));
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: userFriendlyMessage(context, error),
        onRetry: () => ref.invalidate(groupPhotoAlbumProvider(groupId)),
      ),
      data: (photos) {
        if (photos.isEmpty) {
          return const _EmptyState(text: 'Chưa có ảnh giao dịch trong nhóm.');
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return InkWell(
              onTap: () => context.push(
                GroupTransactionDetailScreen.routePath,
                extra: photo.transactionId,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SupabaseImage(
                      imagePath: photo.imagePath,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    photo.caption ?? 'Ảnh giao dịch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${photo.creatorName ?? 'Thành viên'} • ${DateFormat('MM/yyyy').format(photo.transactionDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSubtle),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final statsAsync = ref.watch(
      groupMonthlyStatsProvider((groupId: groupId, month: month)),
    );
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: userFriendlyMessage(context, error),
        onRetry: () => ref.invalidate(
          groupMonthlyStatsProvider((groupId: groupId, month: month)),
        ),
      ),
      data: (stats) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng kết tháng', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text(
                  DateFormat('MM/yyyy').format(stats.month),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  ref.formatAmount(stats.totalSpent),
                  style: const TextStyle(
                    color: AppTheme.mintSoft,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text('${stats.transactionCount} giao dịch nhóm'),
                if (stats.topCategoryName != null)
                  Text(
                    'Top chi: ${stats.topCategoryName} (${ref.formatAmount(stats.topCategoryAmount)})',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Share.share(_summaryText(ref, stats)),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Chia sẻ summary'),
          ),
        ],
      ),
    );
  }

  String _summaryText(WidgetRef ref, GroupMonthlyStats stats) {
    return 'Moniary - Tổng kết nhóm ${DateFormat('MM/yyyy').format(stats.month)}\n'
        'Tổng chi: ${ref.formatAmount(stats.totalSpent)}\n'
        'Số giao dịch: ${stats.transactionCount}\n'
        'Top chi: ${stats.topCategoryName ?? 'Chưa có'}';
  }
}

class _PublicProfileTab extends ConsumerWidget {
  const _PublicProfileTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupPublicProfileProvider(groupId));
    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: userFriendlyMessage(context, error),
        onRetry: () => ref.invalidate(groupPublicProfileProvider(groupId)),
      ),
      data: (profile) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: profile.isEnabled,
                  onChanged: (value) =>
                      _update(ref, profile.copyWith(isEnabled: value)),
                  title: const Text('Bật hồ sơ nhóm công khai'),
                  subtitle: const Text('Trang nhóm có thể chia sẻ được.'),
                ),
                SwitchListTile(
                  value: profile.showStats,
                  onChanged: profile.isEnabled
                      ? (value) =>
                            _update(ref, profile.copyWith(showStats: value))
                      : null,
                  title: const Text('Hiển thị stats công khai'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PreviewBox(profile: profile),
        ],
      ),
    );
  }

  Future<void> _update(WidgetRef ref, GroupPublicProfile profile) {
    return ref
        .read(groupActionControllerProvider.notifier)
        .updatePublicProfile(profile);
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.profile});

  final GroupPublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final link = profile.slug == null
        ? 'moniary://groups/public'
        : 'moniary://groups/public/${profile.slug}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Public profile preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(profile.isEnabled ? link : 'Hồ sơ công khai đang tắt.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: profile.isEnabled ? () => Share.share(link) : null,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Chia sẻ link'),
          ),
        ],
      ),
    );
  }
}

class _RecurringTab extends ConsumerWidget {
  const _RecurringTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(
      groupRecurringTransactionsProvider(groupId),
    );
    return recurringAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: userFriendlyMessage(context, error),
        onRetry: () =>
            ref.invalidate(groupRecurringTransactionsProvider(groupId)),
      ),
      data: (items) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          FilledButton.icon(
            onPressed: () => _showCreateRecurring(context, ref),
            icon: const Icon(Icons.add_outlined),
            label: const Text('Tạo giao dịch lặp lại'),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const _EmptyInline(text: 'Chưa có giao dịch lặp lại.')
          else
            ...items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: SwitchListTile(
                  value: item.isActive,
                  onChanged: (value) => ref
                      .read(groupActionControllerProvider.notifier)
                      .updateRecurringTransactionActive(
                        recurringTransactionId: item.id,
                        groupId: groupId,
                        isActive: value,
                      ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.frequency} • nhắc trước ${item.notifyDaysBefore} ngày • ${DateFormat('dd/MM/yyyy').format(item.nextRunAt)}',
                  ),
                  secondary: Text(ref.formatAmount(item.amount)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateRecurring(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    var frequency = 'monthly';
    var notifyDaysBefore = 1;
    var nextRunAt = DateTime.now().add(const Duration(days: 30));
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Giao dịch lặp lại'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tên khoản chi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số tiền'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Chu kỳ'),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Hàng tháng'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => frequency = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: notifyDaysBefore,
                  decoration: const InputDecoration(labelText: 'Nhắc trước'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Đúng ngày')),
                    DropdownMenuItem(value: 1, child: Text('1 ngày')),
                    DropdownMenuItem(value: 3, child: Text('3 ngày')),
                    DropdownMenuItem(value: 7, child: Text('7 ngày')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => notifyDaysBefore = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày chạy tiếp theo'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(nextRunAt)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: nextRunAt,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setState(() => nextRunAt = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
    final title = titleController.text.trim();
    final amount = int.tryParse(amountController.text.trim()) ?? 0;
    titleController.dispose();
    amountController.dispose();
    if (result != true || title.isEmpty || amount <= 0) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createRecurringTransaction(
            groupId: groupId,
            title: title,
            amount: amount,
            frequency: frequency,
            nextRunAt: nextRunAt,
            notifyDaysBefore: notifyDaysBefore,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        _EmptyInline(text: text),
      ],
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
