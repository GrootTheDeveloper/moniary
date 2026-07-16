import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../notifications/application/notification_controller.dart';
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/presentation/notification_presentation_resolver.dart';
import '../../../notifications/presentation/notification_route_resolver.dart';
import '../../../notifications/presentation/screens/notification_center_screen.dart';
import 'group_community_screen.dart';

class GroupActivityCenterScreen extends ConsumerWidget {
  const GroupActivityCenterScreen({
    this.groupId,
    this.notificationOnly = false,
    super.key,
  });

  static const routePath = '/groups/activity-center';

  final String? groupId;
  final bool notificationOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = this.groupId;
    if (groupId != null && !notificationOnly) {
      return GroupCommunityScreen(groupId: groupId);
    }
    if (groupId == null) return const NotificationCenterScreen();

    final unreadCount = ref.watch(
      groupUnreadNotificationCountProvider(groupId),
    );
    final actionState = ref.watch(notificationActionControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.moniaryColors.backgroundSoft,
        appBar: AppBar(
          title: Text(context.l10n.groupNotificationsTitle),
          actions: [
            if (unreadCount > 0)
              TextButton(
                onPressed: actionState.isLoading
                    ? null
                    : () => _markAllRead(context, ref, groupId),
                child: Text(context.l10n.notificationsMarkAllRead),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.groupActivityTabNotifications),
              Tab(text: context.l10n.groupActivityTabCommunityNotifications),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _NotificationsTab(
              groupId: groupId,
              category: AppNotificationCategory.group,
            ),
            _NotificationsTab(
              groupId: groupId,
              category: AppNotificationCategory.community,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) async {
    try {
      await ref
          .read(notificationActionControllerProvider.notifier)
          .markAllGroupRead(groupId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab({required this.groupId, required this.category});

  final String groupId;
  final AppNotificationCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GroupNotificationQuery(groupId: groupId, category: category);
    final notificationsAsync = ref.watch(groupNotificationInboxProvider(query));
    final colors = context.moniaryColors;

    return notificationsAsync.when(
      loading: () => const _NotificationLoadingList(),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_none_outlined, color: colors.textDim),
              const SizedBox(height: 10),
              Text(
                userFriendlyMessage(context, error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(groupNotificationInboxProvider(query)),
                icon: const Icon(Icons.refresh_outlined),
                label: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
      data: (notifications) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupNotificationInboxProvider(query));
          await ref.read(groupNotificationInboxProvider(query).future);
        },
        child: notifications.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 320,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 36,
                            color: colors.textDim,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            category == AppNotificationCategory.community
                                ? context.l10n.communityNotificationsEmptyState
                                : context.l10n.groupNotificationsEmptyState,
                            style: TextStyle(color: colors.textDim),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _NotificationRow(
                  groupId: groupId,
                  notification: notifications[index],
                ),
              ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.groupId, required this.notification});

  final String groupId;
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Semantics(
      button: true,
      label: NotificationPresentationResolver.title(
        context.l10n,
        notification,
        languageCode,
      ),
      child: Material(
        color: notification.isRead
            ? colors.surface
            : colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleTap(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      NotificationPresentationResolver.iconFor(notification),
                      color: colors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NotificationPresentationResolver.title(
                            context.l10n,
                            notification,
                            languageCode,
                          ),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(context, languageCode),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textDim),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context, String languageCode) {
    final actor = notification.metadata['actor_name'] as String?;
    final base = NotificationPresentationResolver.subtitle(
      context.l10n,
      notification,
      languageCode,
    );
    final time = _timeAgo(context, notification.createdAt);
    return actor == null || actor.trim().isEmpty
        ? '$base · $time'
        : '${actor.trim()} · $base · $time';
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationActionControllerProvider.notifier)
            .markGroupRead(groupId: groupId, notification: notification);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to sync scoped group notification read state',
          error,
          stackTrace,
        );
      }
    }
    if (!context.mounted) return;
    final destination = NotificationRouteResolver.resolveNotification(
      notification,
    );
    if (destination != NotificationCenterScreen.routePath) {
      await context.push(destination);
    }
  }
}

class _NotificationLoadingList extends StatelessWidget {
  const _NotificationLoadingList();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    itemCount: 5,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) => Container(
      height: 76,
      decoration: BoxDecoration(
        color: context.moniaryColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const LinearProgressIndicator(),
    ),
  );
}

String _timeAgo(BuildContext context, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return context.l10n.commonJustNow;
  if (diff.inMinutes < 60) return context.l10n.commonMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return context.l10n.commonHoursAgo(diff.inHours);
  return context.l10n.commonDaysAgo(diff.inDays);
}
