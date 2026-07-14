import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/transactions/domain/models/transaction_entry.dart';
import 'package:moniary/features/transactions/presentation/detail/day_detail_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  setUp(() {
    TransactionRepository.mockTransactions
      ..clear()
      ..addAll([
        _expense('a', 85000, DateTime(2026, 7, 14, 9), 'Ăn uống'),
        _expense('b', 120000, DateTime(2026, 7, 14, 18), 'Di chuyển'),
      ]);
  });

  tearDown(TransactionRepository.mockTransactions.clear);

  testWidgets('day detail opens image grid view by default', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepository(_FakeSupabaseClient(), useMockData: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DayDetailScreen(date: DateTime(2026, 7, 14)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ảnh'), findsOneWidget);
    expect(find.text('Danh sách'), findsOneWidget);
    expect(find.byType(TransactionGridTile), findsNWidgets(2));
    expect(find.textContaining('85.000'), findsWidgets);
  });
}

TransactionEntry _expense(
  String id,
  double amount,
  DateTime date,
  String category,
) {
  return TransactionEntry(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    note: category,
    imagePath: null,
    transactionDate: date,
    walletId: 'cash',
    walletName: 'Tiền mặt',
    walletColor: '#D9A574',
    categoryId: category,
    categoryName: category,
    categoryColor: '#B85C38',
  );
}
