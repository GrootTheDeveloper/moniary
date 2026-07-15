import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

Session _session() {
  const user = User(
    id: 'user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    email: 'a@gmail.com',
    createdAt: '2026-07-16T00:00:00Z',
  );
  return Session(
    accessToken: 'access-token',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

void main() {
  late _MockSupabaseClient client;
  late _MockGoTrueClient auth;
  late AuthRepository repository;

  setUp(() {
    client = _MockSupabaseClient();
    auth = _MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    final rest = PostgrestClient(
      'https://example.test',
      httpClient: MockClient(
        (request) async => http.Response('', 204, request: request),
      ),
    );
    final initializeUserRpc = rest.rpc<dynamic>('initialize_user');
    when(
      () => client.rpc<dynamic>('initialize_user'),
    ).thenAnswer((_) => initializeUserRpc);
    repository = AuthRepository(client);
  });

  test('seeded credentials create a local mock session', () async {
    final result = await repository.signInWithEmail(
      email: ' A@GMAIL.COM ',
      password: '12345678',
    );

    expect(result?.user.id, 'mock-user-id');
    expect(result?.user.email, 'a@gmail.com');
    verifyNever(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('mock mode rejects credentials outside the seeded account', () async {
    await expectLater(
      repository.signInWithEmail(
        email: 'a@gmail.com',
        password: 'wrong-password',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'invalid_credentials',
        ),
      ),
    );
  });

  test('sign-up authenticates without a CAPTCHA token', () async {
    final session = _session();
    when(
      () => auth.signUp(
        email: 'a@gmail.com',
        password: '12345678',
        emailRedirectTo: AppConstants.supabaseLoginCallbackUrl,
      ),
    ).thenAnswer((_) async => AuthResponse(session: session));

    final result = await repository.signUpWithEmail(
      email: 'a@gmail.com',
      password: '12345678',
    );

    expect(result, same(session));
  });

  test('password reset sends without a CAPTCHA token', () async {
    when(
      () => auth.resetPasswordForEmail(
        'a@gmail.com',
        redirectTo: AppConstants.supabasePasswordResetCallbackUrl,
      ),
    ).thenAnswer((_) async {});

    await repository.requestPasswordReset('a@gmail.com');

    verify(
      () => auth.resetPasswordForEmail(
        'a@gmail.com',
        redirectTo: AppConstants.supabasePasswordResetCallbackUrl,
      ),
    ).called(1);
  });

  test('anonymous sign-in runs without a CAPTCHA token', () async {
    final session = _session();
    when(
      () => auth.signInAnonymously(),
    ).thenAnswer((_) async => AuthResponse(session: session));

    final result = await repository.signInAnonymously();

    expect(result, same(session));
    verify(() => auth.signInAnonymously()).called(1);
  });
}
