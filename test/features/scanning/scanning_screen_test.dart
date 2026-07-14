import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/scanning/presentation/scanning_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('manual entry opens transaction form instead of camera', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: ScanningScreen.routePath,
      routes: [
        GoRoute(
          path: ScanningScreen.routePath,
          builder: (context, state) => const ScanningScreen(),
        ),
        GoRoute(
          path: '/transaction-form',
          builder: (context, state) =>
              const Scaffold(body: Text('manual-form-target')),
        ),
        GoRoute(
          path: '/camera',
          builder: (context, state) =>
              const Scaffold(body: Text('camera-target')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
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
    await tester.scrollUntilVisible(
      find.text('Nhập giao dịch thủ công'),
      120,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Nhập giao dịch thủ công'));
    await tester.pumpAndSettle();

    expect(find.text('manual-form-target'), findsOneWidget);
    expect(find.text('camera-target'), findsNothing);
  });
}
