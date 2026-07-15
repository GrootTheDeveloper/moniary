import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late AuthRepository repository;

  setUp(() {
    repository = AuthRepository(_FakeSupabaseClient());
  });

  Matcher requiresCaptcha() => throwsA(
    isA<AppException>().having(
      (error) => error.code,
      'code',
      'AUTH_CAPTCHA_REQUIRED',
    ),
  );

  test('anonymous sign-in rejects a missing CAPTCHA token', () async {
    await expectLater(repository.signInAnonymously(), requiresCaptcha());
  });

  test('email sign-in and sign-up reject missing CAPTCHA tokens', () async {
    await expectLater(
      repository.signInWithEmail(
        email: 'bee@moniary.app',
        password: 'password123',
      ),
      requiresCaptcha(),
    );
    await expectLater(
      repository.signUpWithEmail(
        email: 'bee@moniary.app',
        password: 'password123',
      ),
      requiresCaptcha(),
    );
  });

  test('password reset rejects a missing CAPTCHA token', () async {
    await expectLater(
      repository.requestPasswordReset('bee@moniary.app'),
      requiresCaptcha(),
    );
  });
}
