import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/calendar/presentation/month/calendar_screen.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:moniary/features/profile/domain/user_profile.dart';
import 'package:moniary/features/settings/application/privacy_controller.dart';
import 'package:moniary/features/transactions/data/repositories/transaction_repository.dart';
import 'package:moniary/features/wallets/data/repositories/wallet_repository.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _TestPrivacyController extends PrivacyController {
  @override
  PrivacyState build() => PrivacyState(isAuthenticated: true);
}

void main() {
  setUp(() {
    TransactionRepository.mockTransactions.clear();
  });

  tearDown(() {
    TransactionRepository.mockTransactions.clear();
  });

  testWidgets('Today toggles between daily and monthly calendar views', (
    tester,
  ) async {
    final supabaseClient = _FakeSupabaseClient();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepository(supabaseClient),
          ),
          walletRepositoryProvider.overrideWithValue(
            WalletRepository(supabaseClient),
          ),
          currentProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'test-user',
              fullName: 'Moniary Tester',
              email: 'tester@moniary.app',
              avatarUrl: null,
              loginProvider: 'guest',
              timezone: 'Asia/Ho_Chi_Minh',
            ),
          ),
          privacyControllerProvider.overrideWith(_TestPrivacyController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('T2'), findsOneWidget);
    expect(
      find.text(
        'Chưa có giao dịch nào trong tháng này. Bạn vẫn có thể chọn ngày hoặc nhấn + để thêm giao dịch.',
      ),
      findsNothing,
    );
    await tester.tap(find.text('Hôm nay'));
    await tester.pumpAndSettle();

    expect(find.text('T2'), findsNothing);

    await tester.tap(find.text('Hôm nay').first);
    await tester.pumpAndSettle();

    expect(find.text('T2'), findsOneWidget);
  });
}
