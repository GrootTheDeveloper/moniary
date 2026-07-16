import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/presentation/login_screen.dart';
import 'package:moniary/features/onboarding/presentation/onboarding_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('shows the configured Supabase authentication entry points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: LoginScreen.routePath,
      routes: [
        GoRoute(
          path: LoginScreen.routePath,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: OnboardingScreen.routePath,
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentSessionProvider.overrideWithValue(null)],
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

    expect(find.byKey(const ValueKey('login_email_submit_button')), findsOne);
    expect(find.byKey(const ValueKey('login_guest_button')), findsOne);
    final introButton = find.byKey(const ValueKey('login_app_intro_button'));
    expect(introButton, findsOne);

    await tester.ensureVisible(introButton);
    await tester.tap(introButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOne);
    expect(find.textContaining('Scan a receipt,'), findsOne);
  });
}
