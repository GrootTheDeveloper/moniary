import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/data/repositories/group_mock_repository.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/presentation/screens/group_community_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    GroupMockDataSource.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Widget app() {
    final repository = GroupMockRepository(
      GroupMockDataSource(currentUserId: 'mock-user-id'),
    );
    return ProviderScope(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: const GroupCommunityScreen(groupId: 'mock-group-dalat'),
      ),
    );
  }

  testWidgets(
    'challenge money flow uses one stable dialog and accepts formatted input',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final action = find.text('Tạo thử thách tiết kiệm');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'Tên thử thách'),
        'Quỹ dự phòng',
      );
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Số tiền mục tiêu'),
        '1000000',
      );
      expect(find.text('1.000.000'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Quỹ dự phòng'), findsOneWidget);
      await tester.tap(find.text('Tạo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Quỹ dự phòng'), findsOneWidget);
    },
  );
}
