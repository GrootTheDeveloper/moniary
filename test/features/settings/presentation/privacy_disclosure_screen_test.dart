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
  testWidgets('third-party services disclose configured auth providers', (
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
    expect(find.text('Cloudflare Turnstile'), findsNothing);
  });

  testWidgets('privacy policy discloses authentication providers', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const PrivacyPolicyScreen()));

    final disclosure = find.textContaining(
      'When you choose email, Google, or Facebook (Meta) sign-in',
    );
    await tester.scrollUntilVisible(
      disclosure,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(disclosure, findsOneWidget);

    final personalInfo = find.textContaining(
      'email, Google, or Facebook (Meta)',
    );
    await tester.scrollUntilVisible(
      personalInfo.last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(personalInfo, findsWidgets);
  });
}
