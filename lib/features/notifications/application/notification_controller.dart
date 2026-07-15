import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/app_logger.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/entities/app_notification.dart';
import '../domain/repositories/notification_repository.dart';

final notificationCategoryProvider =
    NotifierProvider<NotificationCategoryNotifier, AppNotificationCategory?>(
      NotificationCategoryNotifier.new,
    );

class NotificationCategoryNotifier extends Notifier<AppNotificationCategory?> {
  @override
  AppNotificationCategory? build() => null;

  void setCategory(AppNotificationCategory? category) => state = category;
}

class NotificationPaginationState {
  const NotificationPaginationState({
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final bool hasMore;
  final bool isLoadingMore;

  NotificationPaginationState copyWith({bool? hasMore, bool? isLoadingMore}) {
    return NotificationPaginationState(
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final notificationPaginationProvider =
    NotifierProvider<
      NotificationPaginationController,
      NotificationPaginationState
    >(NotificationPaginationController.new);

class NotificationPaginationController
    extends Notifier<NotificationPaginationState> {
  @override
  NotificationPaginationState build() => const NotificationPaginationState();

  void update({required bool hasMore, required bool isLoadingMore}) {
    state = NotificationPaginationState(
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
    );
  }
}

class GroupNotificationQuery {
  const GroupNotificationQuery({required this.groupId, this.category});

  final String groupId;
  final AppNotificationCategory? category;

  @override
  bool operator ==(Object other) =>
      other is GroupNotificationQuery &&
      other.groupId == groupId &&
      other.category == category;

  @override
  int get hashCode => Object.hash(groupId, category);
}

final groupNotificationInboxProvider = FutureProvider.autoDispose
    .family<List<AppNotification>, GroupNotificationQuery>((ref, query) async {
      final repository = ref.watch(notificationRepositoryProvider);
      final page = await _fetchPage(
        repository,
        category: query.category,
        groupId: query.groupId,
        limit: 100,
      );
      return page.items;
    });

final groupNotificationUnreadSummaryProvider = FutureProvider.autoDispose
    .family<NotificationUnreadSummary, String>((ref, groupId) {
      final repository = ref.watch(notificationRepositoryProvider);
      if (repository is AdvancedNotificationRepository) {
        return (repository as AdvancedNotificationRepository)
            .fetchUnreadSummary(groupId: groupId);
      }
      return repository
          .fetchNotifications(groupId: groupId)
          .then(NotificationUnreadSummary.fromNotifications);
    });

final groupUnreadNotificationCountProvider = Provider.autoDispose
    .family<int, String>((ref, groupId) {
      return ref
              .watch(groupNotificationUnreadSummaryProvider(groupId))
              .asData
              ?.value
              .total ??
          0;
    });

final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

class NotificationsController extends AsyncNotifier<List<AppNotification>> {
  DateTime? _nextCursor;
  bool _hasMore = false;

  @override
  Future<List<AppNotification>> build() async {
    final category = ref.watch(notificationCategoryProvider);
    final page = await _fetchPage(
      ref.read(notificationRepositoryProvider),
      category: category,
    );
    _nextCursor = page.nextCursor;
    _hasMore = page.hasMore;
    unawaited(
      Future<void>.microtask(() {
        if (!ref.mounted) return;
        ref
            .read(notificationPaginationProvider.notifier)
            .update(hasMore: _hasMore, isLoadingMore: false);
      }),
    );
    return page.items;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !_hasMore) return;
    final pagination = ref.read(notificationPaginationProvider);
    if (pagination.isLoadingMore) return;

    ref
        .read(notificationPaginationProvider.notifier)
        .update(hasMore: _hasMore, isLoadingMore: true);
    try {
      final page = await _fetchPage(
        ref.read(notificationRepositoryProvider),
        category: ref.read(notificationCategoryProvider),
        before: _nextCursor,
      );
      final identities = current.map((item) => item.identity).toSet();
      final appended = page.items
          .where((item) => identities.add(item.identity))
          .toList(growable: false);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore && appended.isNotEmpty;
      state = AsyncData([...current, ...appended]);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to load more notifications', error, stackTrace);
      rethrow;
    } finally {
      if (ref.mounted) {
        ref
            .read(notificationPaginationProvider.notifier)
            .update(hasMore: _hasMore, isLoadingMore: false);
      }
    }
  }

  Future<void> setReadState(
    AppNotification notification, {
    required bool isRead,
  }) async {
    final current = state.asData?.value;
    if (current == null || notification.isRead == isRead) return;

    state = AsyncData(
      current
          .map(
            (item) => item.identity == notification.identity
                ? item.copyWith(isRead: isRead)
                : item,
          )
          .toList(growable: false),
    );
    try {
      final repository = ref.read(notificationRepositoryProvider);
      if (repository is AdvancedNotificationRepository) {
        await (repository as AdvancedNotificationRepository)
            .setNotificationReadState(notification, isRead: isRead);
      } else if (isRead) {
        await repository.markRead(notification.id);
      } else {
        throw UnsupportedError('Mark unread requires notification RPC v2.');
      }
      ref.invalidate(notificationUnreadSummaryProvider);
    } catch (error) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        current
            .map((item) => item.copyWith(isRead: true))
            .toList(growable: false),
      );
    }
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationUnreadSummaryProvider);
    } catch (error) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationUnreadSummaryProvider =
    FutureProvider<NotificationUnreadSummary>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      if (repository is AdvancedNotificationRepository) {
        return (repository as AdvancedNotificationRepository)
            .fetchUnreadSummary();
      }
      return repository.fetchNotifications().then(
        NotificationUnreadSummary.fromNotifications,
      );
    });

final unreadNotificationCountProvider = Provider<int>((ref) {
  final summary = ref.watch(notificationUnreadSummaryProvider).asData?.value;
  if (summary != null) return summary.total;

  // Compatibility while summary is loading: only an unfiltered inbox may be
  // used as a fallback, so a selected UI chip can never corrupt global badges.
  if (ref.watch(notificationCategoryProvider) != null) return 0;
  final notifications = ref.watch(notificationsProvider).asData?.value;
  return notifications?.where((item) => !item.isRead).length ?? 0;
});

final notificationActionControllerProvider =
    AsyncNotifierProvider<NotificationActionController, void>(
      NotificationActionController.new,
    );

class NotificationActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(AppNotification notification) async {
    await _run(
      () => ref
          .read(notificationsProvider.notifier)
          .setReadState(notification, isRead: true),
    );
  }

  Future<void> markUnread(AppNotification notification) async {
    await _run(
      () => ref
          .read(notificationsProvider.notifier)
          .setReadState(notification, isRead: false),
    );
  }

  Future<void> markAllRead() async {
    await _run(ref.read(notificationsProvider.notifier).markAllRead);
  }

  Future<void> markGroupRead({
    required String groupId,
    required AppNotification notification,
  }) async {
    await _run(() async {
      final repository = ref.read(notificationRepositoryProvider);
      if (repository is AdvancedNotificationRepository) {
        await (repository as AdvancedNotificationRepository)
            .setNotificationReadState(notification, isRead: true);
      } else {
        await repository.markRead(notification.id);
      }
      _invalidateGroupNotifications(groupId);
    });
  }

  Future<void> markAllGroupRead(String groupId) async {
    await _run(() async {
      await ref
          .read(notificationRepositoryProvider)
          .markAllRead(groupId: groupId);
      _invalidateGroupNotifications(groupId);
    });
  }

  void _invalidateGroupNotifications(String groupId) {
    ref.invalidate(groupNotificationInboxProvider);
    ref.invalidate(groupNotificationUnreadSummaryProvider(groupId));
    ref.invalidate(notificationUnreadSummaryProvider);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      AppLogger.error('Notification action failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

Future<NotificationPage> _fetchPage(
  NotificationRepository repository, {
  AppNotificationCategory? category,
  String? groupId,
  DateTime? before,
  int limit = 30,
}) async {
  if (repository is AdvancedNotificationRepository) {
    return (repository as AdvancedNotificationRepository).fetchNotificationPage(
      category: category,
      groupId: groupId,
      before: before,
      limit: limit,
    );
  }
  final all = await repository.fetchNotifications(
    category: category,
    groupId: groupId,
  );
  final filtered = before == null
      ? all
      : all.where((item) => item.createdAt.isBefore(before)).toList();
  final items = filtered.take(limit).toList(growable: false);
  return NotificationPage(
    items: items,
    nextCursor: items.isEmpty ? null : items.last.createdAt,
    hasMore: filtered.length > items.length,
  );
}
