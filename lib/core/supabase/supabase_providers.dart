import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../preferences/preferences_providers.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class MockSessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  void setSession(Session? session) {
    state = session;
  }
}

final mockSessionProvider = NotifierProvider<MockSessionNotifier, Session?>(
  MockSessionNotifier.new,
);

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final stream = client.auth.onAuthStateChange;

  if (!AppConstants.hasSupabaseConfig) {
    stream.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        ref.read(sharedPreferencesProvider).setBool('mock_logged_in', false);
        ref.read(mockSessionProvider.notifier).setSession(null);
      }
    });
  }

  return stream;
});

final currentSessionProvider = Provider<Session?>((ref) {
  if (!AppConstants.hasSupabaseConfig) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isLoggedIn = prefs.getBool('mock_logged_in') ?? false;
    if (isLoggedIn) {
      return ref.watch(mockSessionProvider) ?? _createMockSession();
    }
    return ref.watch(mockSessionProvider);
  }
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

Session _createMockSession() {
  const user = User(
    id: 'mock-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-05-28T00:00:00Z',
  );
  return Session(
    accessToken: 'mockAccessToken',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}
