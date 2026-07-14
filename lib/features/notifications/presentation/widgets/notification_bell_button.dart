import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../application/notification_controller.dart';
import '../screens/notification_center_screen.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider);
    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      onPressed: () => context.push(NotificationCenterScreen.routePath),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(
          count > 0
              ? Icons.notifications_active_outlined
              : Icons.notifications_none_outlined,
        ),
      ),
    );
  }
}
