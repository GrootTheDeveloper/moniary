import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/data/repositories/group_mock_repository.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/presentation/screens/add_group_transaction_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    GroupMockDataSource.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('mock account can select an expense category', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = GroupMockRepository(
      GroupMockDataSource(currentUserId: 'mock-user-id'),
    );
    await repository.fetchGroups();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme,
          home: const AddGroupTransactionScreen(
            args: AddGroupTransactionArgs(groupId: 'mock-group-dalat'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final categoryField = find.text('Danh mục');
    expect(categoryField, findsOneWidget);
    await tester.tap(categoryField);
    await tester.pumpAndSettle();

    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Di chuyển'), findsOneWidget);

    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ăn uống'), findsOneWidget);
  });
}
