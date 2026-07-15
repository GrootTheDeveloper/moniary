import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/groups/presentation/screens/group_invitations_screen.dart';
import 'package:moniary/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:moniary/features/notifications/domain/entities/app_notification.dart';
import 'package:moniary/features/notifications/domain/repositories/notification_repository.dart';
import 'package:moniary/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('mark-read failure does not block target navigation', (
    tester,
  ) async {
    final repository = _FailingMarkReadRepository();
    final router = GoRouter(
      initialLocation: NotificationCenterScreen.routePath,
      routes: [
        GoRoute(
          path: NotificationCenterScreen.routePath,
          builder: (_, _) => const NotificationCenterScreen(),
        ),
        GoRoute(
          path: GroupInvitationsScreen.routePath,
          builder: (_, _) => const Scaffold(body: Text('invite-target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bạn được mời vào một group'));
    await tester.pumpAndSettle();

    expect(repository.markReadCalls, ['notification-1']);
    expect(find.text('invite-target'), findsOneWidget);
  });
}

class _FailingMarkReadRepository implements NotificationRepository {
  final markReadCalls = <String>[];

  @override
  Future<List<AppNotification>> fetchNotifications({
    AppNotificationCategory? category,
  }) async => [
    AppNotification(
      id: 'notification-1',
      category: AppNotificationCategory.group,
      type: 'group_invite',
      isRead: false,
      createdAt: DateTime(2026, 7, 15),
      groupId: 'group-1',
    ),
  ];

  @override
  Future<void> markRead(String notificationId) async {
    markReadCalls.add(notificationId);
    throw StateError('backend unavailable');
  }

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
    required String locale,
    required String timezone,
  }) async {}

  @override
  Future<void> unregisterDevice(String token) async {}
}
