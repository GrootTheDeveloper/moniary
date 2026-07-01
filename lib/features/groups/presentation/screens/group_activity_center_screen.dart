import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupActivityCenterScreen extends ConsumerWidget {
  const GroupActivityCenterScreen({required this.groupId, super.key});

  static const routePath = '/groups/activity-center';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hoạt động & thông báo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Timeline'),
              Tab(text: 'Tuỳ chọn'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ActivityTimeline(groupId: groupId),
            _NotificationPreferencePanel(groupId: groupId),
          ],
        ),
      ),
    );
  }
}

class _ActivityTimeline extends ConsumerWidget {
  const _ActivityTimeline({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(groupActivitiesProvider(groupId));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(groupActivitiesProvider(groupId)),
      child: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupActivitiesProvider(groupId)),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return const _EmptyState(text: 'Chưa có hoạt động nhóm.');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surfaceRaised,
                  child: Icon(
                    _iconFor(activity.type),
                    color: AppTheme.mintSoft,
                  ),
                ),
                title: Text(_activityText(activity)),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(activity.createdAt),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('comment')) return Icons.mode_comment_outlined;
    if (type.contains('reaction')) return Icons.add_reaction_outlined;
    if (type.contains('budget')) return Icons.savings_outlined;
    if (type.contains('recurring')) return Icons.event_repeat_outlined;
    if (type.contains('transaction')) return Icons.receipt_long_outlined;
    if (type.contains('member')) return Icons.group_outlined;
    return Icons.history_outlined;
  }

  String _activityText(GroupActivity activity) {
    final actor = activity.actorName ?? 'Thành viên';
    return switch (activity.type) {
      'member_joined' => '$actor đã tham gia nhóm.',
      'member_left' => '$actor đã rời nhóm.',
      'transaction_created' => '$actor đã tạo giao dịch nhóm.',
      'transaction_posted' => '$actor đã đăng giao dịch nhóm.',
      'transaction_reacted' =>
        '$actor đã thả cảm xúc ${activity.metadata['emoji'] ?? ''}.',
      'comment_added' => '$actor đã bình luận trong giao dịch.',
      'budget_updated' => '$actor đã cập nhật ngân sách nhóm.',
      'recurring_created' => '$actor đã tạo giao dịch lặp lại.',
      'public_profile_updated' => '$actor đã cập nhật hồ sơ công khai.',
      'owner_transferred' => '$actor đã chuyển quyền owner của nhóm.',
      'leave_blocked_unresolved' =>
        'Có thành viên cố rời nhóm khi còn khoản nợ chưa xử lý.',
      _ => '$actor đã cập nhật nhóm.',
    };
  }
}

class _NotificationPreferencePanel extends ConsumerWidget {
  const _NotificationPreferencePanel({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferenceAsync = ref.watch(
      groupNotificationPreferenceProvider(groupId),
    );
    return preferenceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: userFriendlyMessage(context, error),
        onRetry: () =>
            ref.invalidate(groupNotificationPreferenceProvider(groupId)),
      ),
      data: (preference) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _PreferenceCard(
              children: [
                SwitchListTile(
                  value: preference.muteAll,
                  onChanged: (value) =>
                      _update(ref, preference.copyWith(muteAll: value)),
                  title: const Text('Tắt toàn bộ thông báo nhóm'),
                  subtitle: const Text('Ẩn notification mới của nhóm này.'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: preference.transactionNotifications,
                  onChanged: preference.muteAll
                      ? null
                      : (value) => _update(
                          ref,
                          preference.copyWith(transactionNotifications: value),
                        ),
                  title: const Text('Giao dịch mới và thay đổi chia tiền'),
                ),
                SwitchListTile(
                  value: preference.debtNotifications,
                  onChanged: preference.muteAll
                      ? null
                      : (value) => _update(
                          ref,
                          preference.copyWith(debtNotifications: value),
                        ),
                  title: const Text('Công nợ và thanh toán'),
                ),
                SwitchListTile(
                  value: preference.inviteNotifications,
                  onChanged: preference.muteAll
                      ? null
                      : (value) => _update(
                          ref,
                          preference.copyWith(inviteNotifications: value),
                        ),
                  title: const Text('Lời mời nhóm'),
                ),
                SwitchListTile(
                  value: preference.mentionNotifications,
                  onChanged: preference.muteAll
                      ? null
                      : (value) => _update(
                          ref,
                          preference.copyWith(mentionNotifications: value),
                        ),
                  title: const Text('@mention trong bình luận'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PreferenceCard(
              children: [
                SwitchListTile(
                  value: preference.quietHoursStart != null,
                  onChanged: preference.muteAll
                      ? null
                      : (value) => _update(
                          ref,
                          value
                              ? preference.copyWith(
                                  quietHoursStart: 22,
                                  quietHoursEnd: 7,
                                )
                              : preference.copyWith(clearQuietHours: true),
                        ),
                  title: const Text('Quiet hours'),
                  subtitle: Text(
                    preference.quietHoursStart == null
                        ? 'Chưa bật giờ yên lặng.'
                        : 'Không nhận thông báo từ ${preference.quietHoursStart}:00 đến ${preference.quietHoursEnd}:00.',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _update(WidgetRef ref, GroupNotificationPreference preference) {
    return ref
        .read(groupActionControllerProvider.notifier)
        .updateNotificationPreference(preference);
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(text),
        ),
      ],
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
