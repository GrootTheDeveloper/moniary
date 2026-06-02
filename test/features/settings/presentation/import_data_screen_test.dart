import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/settings/application/import_controller.dart';
import 'package:moniary/features/settings/domain/models/csv_transaction_row.dart';
import 'package:moniary/features/settings/presentation/import/import_data_screen.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class TestImportController extends ImportController {
  @override
  ImportState build() {
    return ImportState(
      parsedRows: [
        CsvTransactionRow(
          date: DateTime(2026, 6, 2),
          amount: 100000,
          typeStr: 'Chi',
          categoryName: 'An uong',
          note: 'Lunch',
          isValid: true,
        ),
      ],
    );
  }
}

class FailingWalletsController extends WalletsController {
  @override
  Future<List<Wallet>> build() async {
    throw Exception('raw backend wallet failure');
  }
}

void main() {
  testWidgets('import wallet load error hides raw backend details', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importControllerProvider.overrideWith(TestImportController.new),
          importHistoryProvider.overrideWith((ref) async => const []),
          walletsControllerProvider.overrideWith(FailingWalletsController.new),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ImportDataScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(l10n.importErrorWallets(l10n.errorGeneric)),
      findsOneWidget,
    );
    expect(find.textContaining('raw backend wallet failure'), findsNothing);
    expect(find.text(l10n.commonRetry), findsOneWidget);
  });
}
