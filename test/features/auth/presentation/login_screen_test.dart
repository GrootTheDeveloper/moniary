import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/post_auth_decision_provider.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/presentation/login_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _RecordingAuthRepository extends AuthRepository {
  _RecordingAuthRepository() : super(_FakeSupabaseClient());

  String? email;
  String? password;

  @override
  Future<Session?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    return null;
  }
}

GoRouter _loginRouter() => GoRouter(
  initialLocation: LoginScreen.routePath,
  routes: [
    GoRoute(
      path: LoginScreen.routePath,
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

Widget _loginApp(GoRouter router, {AuthRepository? repository}) {
  return ProviderScope(
    overrides: [
      currentSessionProvider.overrideWithValue(null),
      authStateChangesProvider.overrideWith(
        (ref) => const Stream<AuthState>.empty(),
      ),
      postAuthDecisionProvider.overrideWith(
        (ref) async => const PostAuthDecision(PostAuthDestination.noSession),
      ),
      if (repository != null)
        authRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('shows the configured Supabase authentication entry points', (
    tester,
  ) async {
    final router = _loginRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_loginApp(router));
    await tester.pump();

    expect(find.byKey(const ValueKey('login_email_submit_button')), findsOne);
    expect(find.byKey(const ValueKey('login_guest_button')), findsOne);
  });

  testWidgets('submits seeded credentials without security verification', (
    tester,
  ) async {
    final repository = _RecordingAuthRepository();
    final router = _loginRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_loginApp(router, repository: repository));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('login_email_field')),
      'a@gmail.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login_password_field')),
      '12345678',
    );
    await tester.tap(find.byKey(const ValueKey('login_email_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.email, 'a@gmail.com');
    expect(repository.password, '12345678');
  });
}
