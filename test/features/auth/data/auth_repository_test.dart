import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/constants/app_constants.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  test('signInAnonymously returns mock session in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = AuthRepository(FakeSupabaseClient(), prefs);

    final session = await repository.signInAnonymously();

    expect(session?.user.id, 'mock-user-id');
    expect(prefs.getBool('mock_logged_in'), isTrue);
  });

  test('signOut clears mock login flag in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({'mock_logged_in': true});
    final prefs = await SharedPreferences.getInstance();
    final repository = AuthRepository(FakeSupabaseClient(), prefs);

    await repository.signOut();

    expect(prefs.getBool('mock_logged_in'), isFalse);
  });

  test('linkEmailAccount reports mock profile update in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = AuthRepository(FakeSupabaseClient(), prefs);

    final usesMockProfile = await repository.linkEmailAccount(
      email: 'bee@moniary.app',
      password: 'password123',
    );

    expect(usesMockProfile, isTrue);
  });

  test('linkGoogleAccount reports mock profile update in mock mode', () async {
    if (AppConstants.hasSupabaseConfig) {
      markTestSkipped('Mock mode test requires missing Supabase config.');
      return;
    }

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = AuthRepository(FakeSupabaseClient(), prefs);

    final usesMockProfile = await repository.linkGoogleAccount();

    expect(usesMockProfile, isTrue);
  });
}
