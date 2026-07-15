import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:moniary/shared/utils/error_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  testWidgets('maps Supabase invalid credentials without exposing raw error', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      ),
    );

    expect(message, 'Email hoặc mật khẩu không đúng.');
  });

  testWidgets('maps disabled OAuth provider to setup guidance', (tester) async {
    final message = await messageFor(
      tester,
      const AppException(
        'Unsupported provider: facebook',
        code: 'provider_disabled',
      ),
    );

    expect(message, 'Phương thức đăng nhập này chưa được cấu hình.');
  });

  testWidgets('maps stale PKCE callback to retry guidance', (tester) async {
    final message = await messageFor(
      tester,
      const AppException('Flow state expired', code: 'flow_state_expired'),
    );

    expect(
      message,
      'Liên kết đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng bắt đầu lại.',
    );
  });

  testWidgets('maps incomplete Facebook linking to retry guidance', (
    tester,
  ) async {
    final message = await messageFor(
      tester,
      const AppException(
        'Facebook identity linking has not completed',
        code: 'AUTH_LINK_FACEBOOK_NOT_COMPLETED',
      ),
    );

    expect(
      message,
      'Hãy hoàn tất xác thực Facebook trước khi liên kết tài khoản.',
    );
  });

  testWidgets('maps an expired account restoration window', (tester) async {
    final message = await messageFor(
      tester,
      const AppException(
        'Account restoration window has expired',
        code: 'ACCOUNT_RESTORE_EXPIRED',
      ),
    );

    expect(
      message,
      'Thời hạn khôi phục 30 ngày đã kết thúc. '
      'Tài khoản của bạn không thể khôi phục được nữa.',
    );
  });
}
