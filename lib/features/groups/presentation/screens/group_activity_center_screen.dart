import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import 'group_detail_screen.dart';
import 'group_transaction_detail_screen.dart';

class GroupActivityCenterScreen extends ConsumerWidget {
  const GroupActivityCenterScreen({this.groupId, super.key});

  static const routePath = '/groups/activity-center';

  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = this.groupId;
    final tabs = <Tab>[
      if (groupId != null) Tab(text: context.l10n.groupActivityTabTimeline),
      Tab(text: context.l10n.groupActivityTabNotifications),
      Tab(text: context.l10n.groupActivityTabCommunityNotifications),
    ];
    final views = <Widget>[
      if (groupId != null) _ActivityTimelineTab(groupId: groupId),
      const _NotificationsTab(category: 'group'),
      const _NotificationsTab(category: 'community'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.groupActivityCenterTitle),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

class _ActivityTimelineTab extends ConsumerWidget {
  const _ActivityTimelineTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(groupActivitiesProvider(groupId));
    final colors = context.moniaryColors;

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFriendlyMessage(context, error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (activities) {
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(groupActivitiesProvider(groupId)),
          child: activities.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: Text(
                          context.l10n.groupActivityEmpty,
                          style: TextStyle(color: colors.textDim),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: activities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _ActivityRow(activity: activities[index]),
                ),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final GroupActivity activity;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final actor = activity.actorName?.trim().isNotEmpty == true
        ? activity.actorName!
        : context.l10n.groupUnknownMember;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activityIcon(activity.type),
              size: 17,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$actor ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: _activityLabel(context, activity.type)),
                    ],
                  ),
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeAgo(context, activity.createdAt),
                  style: TextStyle(color: colors.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'transaction_reacted':
        return Icons.favorite_outline;
      case 'transaction_commented':
        return Icons.mode_comment_outlined;
      case 'member_joined_by_link':
      case 'member_invitation_accepted':
        return Icons.person_add_outlined;
      case 'member_left':
        return Icons.logout_outlined;
      case 'member_invitation_declined':
        return Icons.person_off_outlined;
      case 'member_removed':
        return Icons.person_remove_outlined;
      case 'owner_transferred':
        return Icons.swap_horiz_outlined;
      case 'settlement_disputed':
        return Icons.report_problem_outlined;
      case 'leave_blocked_unresolved':
        return Icons.warning_amber_outlined;
      default:
        return Icons.bolt_outlined;
    }
  }

  String _activityLabel(BuildContext context, String type) {
    switch (type) {
      case 'transaction_reacted':
        return context.l10n.groupActivityTransactionReacted;
      case 'transaction_commented':
        return context.l10n.groupActivityTransactionCommented;
      case 'member_joined_by_link':
      case 'member_invitation_accepted':
        return context.l10n.groupActivityMemberJoined;
      case 'member_left':
        return context.l10n.groupActivityMemberLeft;
      case 'member_invitation_declined':
        return context.l10n.groupActivityInvitationDeclined;
      case 'member_removed':
        return context.l10n.groupActivityMemberRemoved;
      case 'owner_transferred':
        return context.l10n.groupActivityOwnerTransferred;
      case 'settlement_disputed':
        return context.l10n.groupActivitySettlementDisputed;
      case 'leave_blocked_unresolved':
        return context.l10n.groupActivityLeaveBlocked;
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = category == 'community'
        ? ref.watch(communityNotificationsProvider)
        : ref.watch(groupNotificationsProvider);
    final colors = context.moniaryColors;

    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFriendlyMessage(context, error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (notifications) {
        return RefreshIndicator(
          onRefresh: () async => category == 'community'
              ? ref.invalidate(communityNotificationsProvider)
              : ref.invalidate(groupNotificationsProvider),
          child: notifications.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: Text(
                          category == 'community'
                              ? context.l10n.communityNotificationsEmptyState
                              : context.l10n.groupNotificationsEmptyState,
                          style: TextStyle(color: colors.textDim),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _NotificationRow(notification: notifications[index]),
                ),
        );
      },
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final GroupNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Material(
      color: notification.isRead
          ? Colors.transparent
          : colors.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notification.isRead
                      ? Colors.transparent
                      : AppTheme.terracotta,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _notificationLabel(context, notification.type),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${notification.groupName} · '
                      '${_timeAgo(context, notification.createdAt)}',
                      style: TextStyle(color: colors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      await ref
          .read(groupActionControllerProvider.notifier)
          .markNotificationRead(notification.id);
    }
    final transactionId = notification.groupTransactionId;
    if (transactionId != null && context.mounted) {
      await context.push(
        GroupTransactionDetailScreen.routePath,
        extra: transactionId,
      );
    } else if (context.mounted) {
      await context.push(
        GroupDetailScreen.routePath,
        extra: notification.groupId,
      );
    }
  }

  String _notificationLabel(BuildContext context, String type) {
    switch (type) {
      case 'transaction_posted':
        return context.l10n.groupNotificationTransactionPosted;
      case 'member_amount_required':
        return context.l10n.groupNotificationMemberAmountRequired;
      case 'debt_settled':
        return context.l10n.groupNotificationDebtSettled;
      case 'group_invite':
        return context.l10n.groupNotificationGroupInvite;
      case 'settlement_marked_paid':
        return context.l10n.groupNotificationSettlementMarkedPaid;
      case 'settlement_completed':
        return context.l10n.groupNotificationSettlementCompleted;
      case 'settlement_disputed':
        return context.l10n.groupNotificationSettlementDisputed;
      case 'member_removed':
        return context.l10n.groupNotificationMemberRemoved;
      case 'member_left':
        return context.l10n.groupNotificationMemberLeft;
      case 'member_leave_blocked_warning':
        return context.l10n.groupNotificationLeaveBlocked;
      case 'comment_added':
      case 'transaction_commented':
        return context.l10n.groupNotificationCommentAdded;
      case 'transaction_reacted':
        return context.l10n.groupNotificationReactionAdded;
      case 'comment_mention':
      case 'mention':
        return context.l10n.groupNotificationMention;
      default:
        return context.l10n.groupNotificationGeneric;
    }
  }
}

String _timeAgo(BuildContext context, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return context.l10n.commonJustNow;
  if (diff.inMinutes < 60) return context.l10n.commonMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return context.l10n.commonHoursAgo(diff.inHours);
  return context.l10n.commonDaysAgo(diff.inDays);
}
