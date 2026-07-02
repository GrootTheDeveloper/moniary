import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:moniary/shared/utils/error_helpers.dart';

void main() {
  Future<String> messageFor(WidgetTester tester, Object error) async {
    late String message;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            message = userFriendlyMessage(context, error);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return message;
  }

  testWidgets('maps auth required code to localized login error', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AppException('Missing auth user', code: 'AUTH_REQUIRED'),
    );

    expect(message, 'Bạn chưa đăng nhập.');
  });

  testWidgets('hides raw AppException messages behind generic text', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AppException(
        'PostgrestException(message: database unavailable)',
        code: 'AUTH_SIGN_IN_FAILED',
      ),
    );

    expect(message, 'Đã xảy ra lỗi. Vui lòng thử lại.');
  });

  testWidgets('maps connection key to localized connection error', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AppException('errorConnection'),
    );

    expect(message, 'Lỗi kết nối. Vui lòng thử lại.');
  });

  testWidgets('maps raw socket client errors to localized connection error', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      Exception(
        'ClientException with SocketException: Failed host lookup: '
        'iegjdbcmngtpjoldbixs.supabase.co',
      ),
    );

    expect(message, 'Lỗi kết nối. Vui lòng thử lại.');
  });

  testWidgets('keeps Supabase auth messages for user-actionable errors', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AppException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      ),
    );

    expect(message, 'Invalid login credentials');
  });
}
