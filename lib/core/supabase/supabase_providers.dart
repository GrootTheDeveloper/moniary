import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../preferences/preferences_providers.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

const mockLoggedInPreferenceKey = 'mock_logged_in';
const guestModePreferenceKey = 'guest_mode_enabled';

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

final guestModeEnabledProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final persistedGuestMode = prefs.getBool(guestModePreferenceKey) ?? false;
  final mockSession = ref.watch(mockSessionProvider);
  final hasGuestMockSession = mockSession?.user.id == 'mock-user-id';
  return persistedGuestMode || hasGuestMockSession;
});

final useMockDataModeProvider = Provider<bool>((ref) {
  return !AppConstants.hasSupabaseConfig || ref.watch(guestModeEnabledProvider);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final stream = client.auth.onAuthStateChange;

  if (!AppConstants.hasSupabaseConfig) {
    stream.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        ref
            .read(sharedPreferencesProvider)
            .setBool(mockLoggedInPreferenceKey, false);
        ref.read(mockSessionProvider.notifier).setSession(null);
      }
    });
  }

  return stream;
});

final currentSessionProvider = Provider<Session?>((ref) {
  final isGuestModeEnabled = ref.watch(guestModeEnabledProvider);
  if (!AppConstants.hasSupabaseConfig || isGuestModeEnabled) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isLoggedIn =
        isGuestModeEnabled ||
        (prefs.getBool(mockLoggedInPreferenceKey) ?? false);
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
