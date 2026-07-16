import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moniary/app/app_theme.dart';
import 'package:moniary/app/main_shell_screen.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/assistant/presentation/assistant_intro_screen.dart';
import 'package:moniary/features/recurring/application/recurring_materialization_service.dart';
import 'package:moniary/features/recurring/data/repositories/recurring_transaction_repository.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class _MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  testWidgets('AI bubble always opens the assistant introduction', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'assistant_chat_enabled': true,
      'mascot_enabled': false,
    });
    final preferences = await SharedPreferences.getInstance();
    final recurringRepository = _MockRecurringTransactionRepository();
    when(
      () => recurringRepository.postDueTransactions(
        through: any(named: 'through'),
      ),
    ).thenAnswer((_) async => 0);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShellScreen(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) =>
                      const Scaffold(body: Text('calendar-test')),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/statistics-test',
                  builder: (context, state) => const Scaffold(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/groups-test',
                  builder: (context, state) => const Scaffold(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile-test',
                  builder: (context, state) => const Scaffold(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AssistantIntroScreen.routePath,
          builder: (context, state) =>
              const Scaffold(body: Text('assistant-intro-target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentSessionProvider.overrideWithValue(null),
          recurringMaterializationServiceProvider.overrideWithValue(
            RecurringMaterializationService(recurringRepository),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final assistantBubble = find.byKey(const ValueKey('assistant_chat_bubble'));
    expect(assistantBubble, findsOne);

    await tester.tap(assistantBubble);
    await tester.pumpAndSettle();

    expect(find.text('assistant-intro-target'), findsOne);
  });
}
