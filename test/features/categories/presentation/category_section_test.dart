import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/application/categories_controller.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/categories/presentation/category_section.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

class FailingCategoriesController extends CategoriesController {
  @override
  Future<List<Category>> build() async {
    throw Exception('PostgrestException(raw category failure)');
  }
}

void main() {
  testWidgets('category section hides raw load errors', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('vi'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesControllerProvider.overrideWith(
            FailingCategoriesController.new,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CategorySection()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('PostgrestException'), findsNothing);
    expect(find.textContaining('raw category failure'), findsNothing);
    expect(find.textContaining(l10n.errorGeneric), findsOneWidget);
  });
}
