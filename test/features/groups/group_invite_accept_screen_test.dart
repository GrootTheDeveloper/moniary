import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/entities/group_invite.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';
import 'package:moniary/features/groups/presentation/groups_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_invite_accept_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  Widget app({required GroupRepository repository}) {
    final router = GoRouter(
      initialLocation: '/groups/invite/token-1',
      routes: [
        GoRoute(
          path: GroupInviteAcceptScreen.routePath,
          builder: (context, state) => GroupInviteAcceptScreen(
            token: state.pathParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: GroupsScreen.routePath,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Groups route'))),
        ),
        GoRoute(
          path: GroupDetailScreen.routePath,
          builder: (context, state) =>
              Scaffold(appBar: AppBar(title: const Text('Group detail'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'shared invite preview can be dismissed without accepting the group',
    (tester) async {
      final repository = _MockGroupRepository();
      when(() => repository.fetchInvitePreview('token-1')).thenAnswer(
        (_) async => GroupInvitePreview(
          status: GroupInviteStatus.active,
          groupId: 'group-1',
          groupName: 'Nhóm Đà Lạt',
          inviterName: 'An',
          expiresAt: DateTime(2026, 7, 20),
        ),
      );

      await tester.pumpWidget(app(repository: repository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Bạn chưa tham gia nhóm. Chỉ bấm Tham gia nhóm khi bạn muốn nhận lời mời này.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tham gia nhóm'), findsOneWidget);
      expect(find.text('Không tham gia'), findsOneWidget);

      await tester.ensureVisible(find.text('Không tham gia'));
      await tester.tap(find.text('Không tham gia'));
      await tester.pumpAndSettle();

      expect(find.text('Groups route'), findsOneWidget);
      verifyNever(() => repository.acceptInvite(any()));
    },
  );

  testWidgets('accepted shared invite opens group detail with a back button', (
    tester,
  ) async {
    final repository = _MockGroupRepository();
    when(() => repository.fetchInvitePreview('token-1')).thenAnswer(
      (_) async => GroupInvitePreview(
        status: GroupInviteStatus.active,
        groupId: 'group-1',
        groupName: 'Nhóm Đà Lạt',
        inviterName: 'An',
        expiresAt: DateTime(2026, 7, 20),
      ),
    );
    when(() => repository.acceptInvite('token-1')).thenAnswer(
      (_) async => const GroupInviteAcceptResult(
        status: GroupInviteStatus.accepted,
        groupId: 'group-1',
      ),
    );

    await tester.pumpWidget(app(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tham gia nhóm'));
    await tester.pumpAndSettle();

    expect(find.text('Group detail'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Lời mời vào nhóm'), findsWidgets);
    verify(() => repository.acceptInvite('token-1')).called(1);
  });
}
