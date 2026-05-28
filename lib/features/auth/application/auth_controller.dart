import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!AppConstants.hasSupabaseConfig) {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('mock_logged_in', true);
        const user = User(
          id: 'mock-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-05-28T00:00:00Z',
        );
        final mockSession = Session(
          accessToken: 'mockAccessToken',
          tokenType: 'bearer',
          expiresIn: 3600,
          user: user,
        );
        ref.read(mockSessionProvider.notifier).setSession(mockSession);
        return;
      }

      final client = ref.read(supabaseClientProvider);

      await client.auth.signInAnonymously();

      try {
        await client.rpc('initialize_user');
      } on PostgrestException catch (error) {
        // Allow auth to succeed even if the database migration/RPC is not ready yet.
        debugPrint('initialize_user() failed (non-blocking): ${error.message}');
      }
    });
  }
}
