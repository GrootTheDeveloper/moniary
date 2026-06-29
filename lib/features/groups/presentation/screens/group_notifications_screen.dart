import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import 'group_detail_screen.dart';
import 'group_invite_accept_screen.dart';
import 'group_transaction_detail_screen.dart';

class GroupNotificationsScreen extends ConsumerWidget {
  const GroupNotificationsScreen({super.key});

  static const routePath = '/groups/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(groupNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupNotificationsTitle)),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          AppLogger.error(
            'Failed to load group notifications',
            error,
            stackTrace,
          );
          return _ErrorState(
            message: userFriendlyMessage(context, error),
            onRetry: () => ref.invalidate(groupNotificationsProvider),
          );
        },
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(groupNotificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
                onTap: () =>
                    _openNotification(context, ref, notifications[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    GroupNotification notification,
  ) async {
    await ref
        .read(groupActionControllerProvider.notifier)
        .markNotificationRead(notification.id);
    if (!context.mounted) return;
    final inviteToken = notification.inviteToken;
    if (notification.type == 'group_invite' && inviteToken != null) {
      await context.push(GroupInviteAcceptScreen.routeLocation(inviteToken));
      return;
    }
    final transactionId = notification.groupTransactionId;
    if (transactionId != null) {
      await context.push(
        GroupTransactionDetailScreen.routePath,
        extra: transactionId,
      );
      return;
    }
    await context.push(
      GroupDetailScreen.routePath,
      extra: notification.groupId,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final GroupNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? null : AppTheme.surfaceRaised,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          notification.isRead
              ? Icons.notifications_none_outlined
              : Icons.notifications_active_outlined,
          color: notification.isRead ? AppTheme.mintSoft : AppTheme.amber,
        ),
        title: Text(_title(context, notification.type)),
        subtitle: Text(
          '${notification.groupName} • '
          '${DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt)}',
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.circle, size: 10, color: AppTheme.amber),
      ),
    );
  }

  String _title(BuildContext context, String type) {
    switch (type) {
      case 'group_invite':
        return context.l10n.groupNotificationInvite;
      case 'member_joined':
        return context.l10n.groupNotificationMemberJoined;
      case 'member_amount_required':
      case 'member_amount_input_required':
        return context.l10n.groupTransactionPendingAmounts;
      case 'member_amount_mismatch':
        return context.l10n.groupTransactionAmountMismatch;
      case 'transaction_posted':
      case 'group_transaction_posted':
        return context.l10n.groupTransactionPosted;
      case 'transaction_created':
        return context.l10n.groupNotificationTransactionCreated;
      case 'owner_transferred':
        return context.l10n.groupNotificationOwnerTransferred;
      case 'member_leave_blocked_warning':
        return context.l10n.groupLeaveWarningActivity;
      default:
        return context.l10n.groupNotificationGeneric;
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              size: 72,
              color: AppTheme.mintSoft,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.groupNotificationsEmpty,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
