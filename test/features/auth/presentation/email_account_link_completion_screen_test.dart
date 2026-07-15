import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/presentation/email_account_link_completion_screen.dart';
import 'package:moniary/features/settings/presentation/profile_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _EmailLinkAuthRepository extends AuthRepository {
  _EmailLinkAuthRepository() : super(_FakeSupabaseClient());

  String? linkedPassword;

  @override
  Future<void> completeEmailAccountLink({required String password}) async {
    linkedPassword = password;
  }
}

Widget _testApp(
  _EmailLinkAuthRepository repository,
  SharedPreferences preferences,
) {
  final router = GoRouter(
    initialLocation: EmailAccountLinkCompletionScreen.routePath,
    routes: [
      GoRoute(
        path: EmailAccountLinkCompletionScreen.routePath,
        builder: (context, state) => const EmailAccountLinkCompletionScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) =>
            const Scaffold(body: Text('profile-screen')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      sharedPreferencesProvider.overrideWithValue(preferences),
      supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
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
  testWidgets('requires matching passwords before completing email link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'pending_email_account_link_user_id': 'test-user-id',
      'pending_email_account_link_email': 'bee@moniary.app',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = _EmailLinkAuthRepository();
    await tester.pumpWidget(_testApp(repository, preferences));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('email_link_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email_link_confirm')),
      'different123',
    );
    await tester.tap(find.byKey(const ValueKey('email_link_submit')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repository.linkedPassword, isNull);
  });

  testWidgets('sets password and clears pending email link', (tester) async {
    SharedPreferences.setMockInitialValues({
      'pending_email_account_link_user_id': 'test-user-id',
      'pending_email_account_link_email': 'bee@moniary.app',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = _EmailLinkAuthRepository();
    await tester.pumpWidget(_testApp(repository, preferences));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('email_link_password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('email_link_confirm')),
      'password123',
    );
    await tester.tap(find.byKey(const ValueKey('email_link_submit')));
    await tester.pumpAndSettle();

    expect(repository.linkedPassword, 'password123');
    expect(preferences.getString('pending_email_account_link_email'), isNull);
    expect(find.text('profile-screen'), findsOneWidget);
  });
}
