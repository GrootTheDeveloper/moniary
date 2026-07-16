import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';
import 'package:moniary/features/groups/presentation/screens/create_group_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  testWidgets('create group submits trimmed values and returns the group id', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockGroupRepository();
    when(
      () => repository.createGroup(
        name: 'Nhóm Đà Lạt',
        description: '',
        type: '',
        avatarFilePath: null,
      ),
    ).thenAnswer((_) async => 'group-1');

    final router = GoRouter(
      initialLocation: '/launcher',
      routes: [
        GoRoute(
          path: '/launcher',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await context.push<Object?>(
                  CreateGroupScreen.routePath,
                );
                if (context.mounted && result is CreateGroupResult) {
                  context.go('/result/${result.groupId}');
                }
              },
              child: const Text('Open create'),
            ),
          ),
        ),
        GoRoute(
          path: CreateGroupScreen.routePath,
          builder: (context, state) => const CreateGroupScreen(),
        ),
        GoRoute(
          path: '/result/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Created ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('Open create'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  Nhóm Đà Lạt  ');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Created group-1'), findsOneWidget);
    verify(
      () => repository.createGroup(
        name: 'Nhóm Đà Lạt',
        description: '',
        type: '',
        avatarFilePath: null,
      ),
    ).called(1);
  });
}
