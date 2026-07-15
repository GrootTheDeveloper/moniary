import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../../groups/presentation/screens/group_detail_screen.dart';
import '../../../groups/presentation/screens/group_invitations_screen.dart';
import '../../../groups/presentation/screens/group_transaction_detail_screen.dart';
import '../../application/notification_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../../../../shared/utils/app_logger.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(notificationCategoryProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final actionState = ref.watch(notificationActionControllerProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          if (notificationsAsync.asData?.value.any((item) => !item.isRead) ==
              true)
            TextButton(
              onPressed: actionState.isLoading
                  ? null
                  : () => ref
                        .read(notificationActionControllerProvider.notifier)
                        .markAllRead(),
              child: Text(context.l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilter(
            selected: category,
            onSelected: (value) => ref
                .read(notificationCategoryProvider.notifier)
                .setCategory(value),
          ),
          Expanded(
            child: notificationsAsync.when(
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
              data: (notifications) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 360,
                            child: Center(
                              child: Text(
                                context.l10n.notificationsEmpty,
                                style: TextStyle(color: colors.textDim),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        itemCount: notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) => _NotificationTile(
                          notification: notifications[index],
                          onTap: () => _openNotification(
                            context,
                            ref,
                            notifications[index],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationActionControllerProvider.notifier)
            .markRead(notification.id);
      } catch (error, stackTrace) {
        // Opening the target remains useful even if the read-state update
        // temporarily fails because of a network or backend issue.
        AppLogger.error(
          'Failed to mark notification read before navigation',
          error,
          stackTrace,
        );
      }
    }
    if (!context.mounted) return;

    final transactionId = notification.groupTransactionId;
    if (transactionId != null) {
      await context.push(
        GroupTransactionDetailScreen.routePath,
        extra: transactionId,
      );
      return;
    }

    if (notification.type == 'group_invite') {
      await context.push(GroupInvitationsScreen.routePath);
      return;
    }

    if (notification.friendRequestId != null ||
        notification.category == AppNotificationCategory.personal) {
      await context.push(FriendsScreen.routePath);
      return;
    }

    final groupId = notification.groupId;
    if (groupId != null) {
      await context.push(GroupDetailScreen.routePath, extra: groupId);
    }
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onSelected});

  final AppNotificationCategory? selected;
  final ValueChanged<AppNotificationCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = <AppNotificationCategory?>[
      null,
      AppNotificationCategory.personal,
      AppNotificationCategory.group,
      AppNotificationCategory.community,
      AppNotificationCategory.system,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(_categoryLabel(context, category)),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(
    BuildContext context,
    AppNotificationCategory? category,
  ) {
    return switch (category) {
      null => context.l10n.notificationsFilterAll,
      AppNotificationCategory.personal =>
        context.l10n.notificationsCategoryPersonal,
      AppNotificationCategory.group => context.l10n.notificationsCategoryGroup,
      AppNotificationCategory.community =>
        context.l10n.notificationsCategoryCommunity,
      AppNotificationCategory.system =>
        context.l10n.notificationsCategorySystem,
    };
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: notification.isRead
          ? Colors.transparent
          : colors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(category: notification.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title(context),
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.terracotta,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(context),
                      style: TextStyle(color: colors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _timeAgo(context, notification.createdAt),
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

  String _title(BuildContext context) {
    return switch (notification.type) {
      'friend_request' => context.l10n.notificationFriendRequest,
      'friend_request_accepted' => context.l10n.notificationFriendAccepted,
      'transaction_posted' => context.l10n.notificationGroupTransaction,
      'member_amount_required' => context.l10n.notificationAmountRequired,
      'group_invite' => context.l10n.notificationGroupInvite,
      'debt_settled' => context.l10n.notificationDebtSettled,
      'comment_added' ||
      'transaction_commented' => context.l10n.notificationCommunityComment,
      'transaction_reacted' => context.l10n.notificationCommunityReaction,
      'comment_mention' ||
      'mention' => context.l10n.notificationCommunityMention,
      _ => context.l10n.notificationGeneric,
    };
  }

  String _subtitle(BuildContext context) {
    final category = switch (notification.category) {
      AppNotificationCategory.personal =>
        context.l10n.notificationsCategoryPersonal,
      AppNotificationCategory.group => context.l10n.notificationsCategoryGroup,
      AppNotificationCategory.community =>
        context.l10n.notificationsCategoryCommunity,
      AppNotificationCategory.system =>
        context.l10n.notificationsCategorySystem,
    };
    final groupName = notification.groupName?.trim();
    if (groupName != null && groupName.isNotEmpty) {
      return '$category · $groupName';
    }
    return category;
  }

  String _timeAgo(BuildContext context, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return context.l10n.commonJustNow;
    if (diff.inMinutes < 60) {
      return context.l10n.commonMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) return context.l10n.commonHoursAgo(diff.inHours);
    return context.l10n.commonDaysAgo(diff.inDays);
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final AppNotificationCategory category;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final icon = switch (category) {
      AppNotificationCategory.personal => Icons.person_outline,
      AppNotificationCategory.group => Icons.groups_outlined,
      AppNotificationCategory.community => Icons.forum_outlined,
      AppNotificationCategory.system => Icons.info_outline,
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colors.primary, size: 19),
    );
  }
}
