import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/presentation/login_screen.dart';
import 'package:moniary/features/auth/presentation/password_reset_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class _RecoveryAuthRepository extends AuthRepository {
  _RecoveryAuthRepository() : super(null, useMockData: true);

  String? updatedPassword;

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = password;
  }
}

Widget _testApp(_RecoveryAuthRepository repository) {
  final router = GoRouter(
    initialLocation: PasswordResetScreen.routePath,
    routes: [
      GoRoute(
        path: PasswordResetScreen.routePath,
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const Scaffold(body: Text('login-screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
  testWidgets('requires matching password confirmation', (tester) async {
    final repository = _RecoveryAuthRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('password_reset_password')),
      'new-password-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password_reset_confirm')),
      'different-password',
    );
    await tester.tap(find.byKey(const ValueKey('password_reset_submit')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repository.updatedPassword, isNull);
  });

  testWidgets('updates password and returns to login', (tester) async {
    final repository = _RecoveryAuthRepository();
    await tester.pumpWidget(_testApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('password_reset_password')),
      'new-password-123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('password_reset_confirm')),
      'new-password-123',
    );
    await tester.tap(find.byKey(const ValueKey('password_reset_submit')));
    await tester.pumpAndSettle();

    expect(repository.updatedPassword, 'new-password-123');
    expect(find.text('login-screen'), findsOneWidget);
  });
}
