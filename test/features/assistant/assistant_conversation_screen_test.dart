import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/assistant/data/assistant_repository_impl.dart';
import 'package:moniary/features/assistant/domain/assistant_models.dart';
import 'package:moniary/features/assistant/domain/assistant_repository.dart';
import 'package:moniary/features/assistant/presentation/assistant_conversation_screen.dart';
import 'package:moniary/features/assistant/presentation/assistant_permission_screen.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:moniary/features/profile/domain/user_profile.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'renders verified insight card even when AI commentary is available',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: AssistantConversationScreen.routePath,
        routes: [
          GoRoute(
            path: AssistantConversationScreen.routePath,
            builder: (context, state) => const AssistantConversationScreen(),
          ),
          GoRoute(
            path: AssistantPermissionScreen.routePath,
            builder: (context, state) =>
                const Scaffold(body: Text('Permission screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            currentSessionProvider.overrideWithValue(null),
            currentProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'user-1',
                fullName: 'Nguyen Minh An',
                email: 'an@example.com',
                avatarUrl: null,
                loginProvider: 'email',
                timezone: 'Asia/Ho_Chi_Minh',
              ),
            ),
            assistantRepositoryProvider.overrideWithValue(
              _CommentaryAssistantRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'How much have I spent this month?',
      );
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(
        find.text(formatCurrency(700000, currencyCode: 'VND', locale: 'vi')),
        findsOneWidget,
      );
      expect(
        find.text('Review your largest category this week.'),
        findsOneWidget,
      );
    },
  );
}

class _CommentaryAssistantRepository implements AssistantRepository {
  @override
  Future<AssistantAccess> loadAccess() async {
    return const AssistantAccess(introSeen: true, enabled: true);
  }

  @override
  Future<void> saveAccess(AssistantAccess access) async {}

  @override
  Future<FinancialAssistantSnapshot> buildSnapshot(
    AssistantSnapshotWindow window,
  ) async {
    return const FinancialAssistantSnapshot(
      monthlyExpense: 700000,
      previousMonthExpense: 500000,
      currentWeekExpense: 250000,
      previousWeekExpense: 200000,
      dailyAverage: 100000,
      topCategoryName: 'Food',
      topCategoryAmount: 500000,
      topCategoryShare: 0.71,
      recurringLabel: null,
      recurringCount: 0,
      recurringAmount: 0,
      suggestedSaving: 70000,
    );
  }

  @override
  Future<String?> generateAnswer({
    required String question,
    required AssistantQuestionKind kind,
    required String locale,
    required String currencyCode,
    required List<AssistantMessage> history,
    FinancialAssistantSnapshot? snapshot,
    String? profileName,
  }) async {
    return 'Review your largest category this week.';
  }
}
