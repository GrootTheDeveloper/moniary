import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/wallets/presentation/wallet_section.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingWalletsController extends WalletsController {
  @override
  Future<List<Wallet>> build() async {
    throw Exception('PostgrestException(raw wallet failure)');
  }
}

class EmptyWalletsController extends WalletsController {
  @override
  Future<List<Wallet>> build() async => const [];
}

class _FakeCurrencyNotifier extends PreferredCurrencyNotifier {
  @override
  String build() => 'VND';
}

class _UnsupportedCurrencyNotifier extends PreferredCurrencyNotifier {
  @override
  String build() => 'AED';
}

void main() {
  testWidgets('wallet section hides raw load errors', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsControllerProvider.overrideWith(FailingWalletsController.new),
          preferredCurrencyProvider.overrideWith(_FakeCurrencyNotifier.new),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WalletSection()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('PostgrestException'), findsNothing);
    expect(find.textContaining('raw wallet failure'), findsNothing);
    expect(find.textContaining(l10n.errorGeneric), findsOneWidget);
  });

  testWidgets(
    'new wallet currency dropdown falls back to VND instead of crashing '
    'when the cached preferred currency has no exchange rate (e.g. AED)',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            walletsControllerProvider.overrideWith(EmptyWalletsController.new),
            preferredCurrencyProvider.overrideWith(
              _UnsupportedCurrencyNotifier.new,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: WalletSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ ${l10n.commonAdd}'));
      await tester.pumpAndSettle();

      // The DropdownButtonFormField would throw an assertion error during
      // this pump if 'AED' were preselected without being in its item list.
      expect(tester.takeException(), isNull);
      expect(find.text('VND (₫)'), findsOneWidget);
    },
  );
}
