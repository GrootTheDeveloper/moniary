import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../settings/presentation/notifications/notification_settings_screen.dart';
import '../../application/notification_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../notification_presentation_resolver.dart';
import '../notification_route_resolver.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  static const routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(notificationCategoryProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final summaryAsync = ref.watch(notificationUnreadSummaryProvider);
    final actionState = ref.watch(notificationActionControllerProvider);
    final summary = summaryAsync.asData?.value;
    final visibleUnread =
        notificationsAsync.asData?.value.where((item) => !item.isRead).length ??
        0;
    final unreadCount = summary?.total ?? visibleUnread;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.notificationsOpenSettings,
            onPressed: () => context.push(NotificationSettingsScreen.routePath),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _InboxSummary(
              unreadCount: unreadCount,
              isLoading: summaryAsync.isLoading,
              canMarkAll: unreadCount > 0,
              isUpdating: actionState.isLoading,
              onMarkAllRead: () => _markAllRead(context, ref),
            ),
            _CategoryFilter(
              selected: category,
              summary: summary,
              onSelected: (value) => ref
                  .read(notificationCategoryProvider.notifier)
                  .setCategory(value),
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const _NotificationSkeletonList(),
                error: (error, stackTrace) => _NotificationError(
                  message: userFriendlyMessage(context, error),
                  onRetry: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                ),
                data: (notifications) => _NotificationList(
                  notifications: notifications,
                  category: category,
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).refresh(),
                  onOpen: (notification) =>
                      _openNotification(context, ref, notification),
                  onToggleRead: (notification) =>
                      _toggleReadState(context, ref, notification),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(notificationActionControllerProvider.notifier)
          .markAllRead();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsMarkAllSuccess)),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to mark all notifications read',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsMarkAllError)),
      );
    }
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
            .markRead(notification);
      } catch (error, stackTrace) {
        AppLogger.error(
          'Failed to mark notification read before navigation',
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

  Future<void> _toggleReadState(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final controller = ref.read(
        notificationActionControllerProvider.notifier,
      );
      if (notification.isRead) {
        await controller.markUnread(notification);
      } else {
        await controller.markRead(notification);
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsReadStateSuccess)),
      );
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsReadStateError)),
      );
    }
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({
    required this.unreadCount,
    required this.isLoading,
    required this.canMarkAll,
    required this.isUpdating,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool isLoading;
  final bool canMarkAll;
  final bool isUpdating;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_outlined,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading && unreadCount == 0
                      ? context.l10n.notificationsTitle
                      : context.l10n.notificationsUnreadCount(unreadCount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount == 0
                      ? context.l10n.notificationsAllCaughtUp
                      : context.l10n.notificationsRetentionHint,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textDim),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: canMarkAll && !isUpdating ? onMarkAllRead : null,
            child: isUpdating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Text(context.l10n.notificationsMarkAllRead),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selected,
    required this.summary,
    required this.onSelected,
  });

  final AppNotificationCategory? selected;
  final NotificationUnreadSummary? summary;
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(_label(context, category)),
              avatar: _count(category) > 0
                  ? Text(
                      _count(category) > 99 ? '99+' : '${_count(category)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  : null,
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _count(AppNotificationCategory? category) =>
      summary?.countFor(category) ?? 0;

  String _label(BuildContext context, AppNotificationCategory? category) {
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

class _NotificationList extends ConsumerWidget {
  const _NotificationList({
    required this.notifications,
    required this.category,
    required this.onRefresh,
    required this.onOpen,
    required this.onToggleRead,
  });

  final List<AppNotification> notifications;
  final AppNotificationCategory? category;
  final Future<void> Function() onRefresh;
  final ValueChanged<AppNotification> onOpen;
  final ValueChanged<AppNotification> onToggleRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [_NotificationEmpty(filtered: category != null)],
        ),
      );
    }

    final sections = _groupNotifications(notifications);
    final pagination = ref.watch(notificationPaginationProvider);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          for (final section in sections) ...[
            _SectionHeader(section: section.key),
            for (final notification in section.value) ...[
              _NotificationTile(
                notification: notification,
                onTap: () => onOpen(notification),
                onToggleRead: () => onToggleRead(notification),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (pagination.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: pagination.isLoadingMore
                    ? null
                    : () => _loadMore(context, ref),
                icon: pagination.isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_outlined),
                label: Text(context.l10n.notificationsLoadMore),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadMore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationsProvider.notifier).loadMore();
    } catch (_) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.notificationsLoadMoreError)),
      );
    }
  }

  List<MapEntry<_NotificationSection, List<AppNotification>>>
  _groupNotifications(List<AppNotification> items) {
    final grouped = <_NotificationSection, List<AppNotification>>{};
    for (final item in items) {
      final section = _sectionFor(item.createdAt);
      grouped.putIfAbsent(section, () => []).add(item);
    }
    return grouped.entries.toList(growable: false);
  }

  _NotificationSection _sectionFor(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (date == today) return _NotificationSection.today;
    if (date == today.subtract(const Duration(days: 1))) {
      return _NotificationSection.yesterday;
    }
    return _NotificationSection.earlier;
  }
}

enum _NotificationSection { today, yesterday, earlier }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final _NotificationSection section;

  @override
  Widget build(BuildContext context) {
    final label = switch (section) {
      _NotificationSection.today => context.l10n.notificationsToday,
      _NotificationSection.yesterday => context.l10n.notificationsYesterday,
      _NotificationSection.earlier => context.l10n.notificationsEarlier,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: context.moniaryColors.textDim,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onToggleRead,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = NotificationPresentationResolver.title(
      context.l10n,
      notification,
      languageCode,
    );
    final subtitle = NotificationPresentationResolver.subtitle(
      context.l10n,
      notification,
      languageCode,
    );
    final time = _timeAgo(context, notification.createdAt);
    final semanticsLabel = [
      if (!notification.isRead) context.l10n.notificationsUnreadSemantics,
      title,
      subtitle,
      time,
      context.l10n.notificationsOpenSemantics,
    ].join('. ');

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: notification.isRead
            ? colors.surface
            : colors.primary.withValues(alpha: 0.09),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: notification.isRead
                ? colors.outline
                : colors.primary.withValues(alpha: 0.32),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationIcon(notification: notification),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          time,
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      PopupMenuButton<bool>(
                        tooltip: notification.isRead
                            ? context.l10n.notificationsMarkUnread
                            : context.l10n.notificationsMarkRead,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert_outlined,
                          color: colors.textDim,
                          size: 20,
                        ),
                        onSelected: (_) => onToggleRead(),
                        itemBuilder: (context) => [
                          PopupMenuItem<bool>(
                            value: !notification.isRead,
                            child: Row(
                              children: [
                                Icon(
                                  notification.isRead
                                      ? Icons.mark_email_unread_outlined
                                      : Icons.mark_email_read_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  notification.isRead
                                      ? context.l10n.notificationsMarkUnread
                                      : context.l10n.notificationsMarkRead,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(
        NotificationPresentationResolver.iconFor(notification),
        color: colors.primary,
        size: 21,
      ),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 44,
                color: colors.textDim,
              ),
              const SizedBox(height: 14),
              Text(
                filtered
                    ? context.l10n.notificationsEmptyCategory
                    : context.l10n.notificationsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.danger, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 92,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline),
        ),
      ),
    );
  }
}
