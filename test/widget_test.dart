import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moniary/app/app.dart';
import 'package:moniary/app/app_router.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';

void main() {
  testWidgets('App shell renders with an injected router', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final testRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Moniary test shell'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MoniaryApp(),
      ),
    );

    expect(find.text('Moniary test shell'), findsOneWidget);
  });
}
