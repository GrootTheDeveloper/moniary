import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/features/wallets/presentation/wallet_section.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class FailingWalletsController extends WalletsController {
  @override
  Future<List<Wallet>> build() async {
    throw Exception('PostgrestException(raw wallet failure)');
  }
}

void main() {
  testWidgets('wallet section hides raw load errors', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsControllerProvider.overrideWith(FailingWalletsController.new),
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
}
