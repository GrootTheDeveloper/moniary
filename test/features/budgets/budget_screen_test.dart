import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/budgets/application/budget_controller.dart';
import 'package:moniary/features/budgets/domain/monthly_budget.dart';
import 'package:moniary/features/budgets/presentation/budget_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  testWidgets('shows monthly total and category budget progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthlyBudgetProvider.overrideWith((ref, month) async {
            return MonthlyBudget(
              month: month,
              categories: const [
                CategoryBudget(
                  categoryId: 'food',
                  categoryName: 'Ăn uống',
                  spentAmount: 900000,
                  limitAmount: 1000000,
                ),
              ],
              unbudgetedCategories: const [],
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BudgetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.textContaining('Sắp vượt', findRichText: true), findsOneWidget);
  });
}
