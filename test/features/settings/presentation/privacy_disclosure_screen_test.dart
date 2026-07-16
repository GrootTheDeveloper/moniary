import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/presentation/legal/third_party_services_screen.dart';
import 'package:moniary/features/settings/presentation/privacy/privacy_policy_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

Widget _localizedApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  testWidgets('third-party services disclose Google, Meta, and Cloudflare', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const ThirdPartyServicesScreen()));

    expect(find.text('Google'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Facebook (Meta)'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Facebook (Meta)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cloudflare Turnstile'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cloudflare Turnstile'), findsOneWidget);
  });

  testWidgets('privacy policy discloses auth providers and CAPTCHA', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const PrivacyPolicyScreen()));

    final disclosure = find.textContaining(
      'Cloudflare Turnstile processes security signals',
    );
    await tester.scrollUntilVisible(
      disclosure,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(disclosure, findsOneWidget);

    final personalInfo = find.text(
      'Personal info: processed when users log in with email, Google, or Facebook (Meta).',
    );
    await tester.scrollUntilVisible(
      personalInfo,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(personalInfo, findsOneWidget);
  });
}
