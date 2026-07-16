import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

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

final guestModeEnabledProvider = Provider<bool>((ref) {
  final mockSession = ref.watch(mockSessionProvider);
  return mockSession?.user.id == 'mock-user-id';
});

final useMockDataModeProvider = Provider<bool>((ref) {
  return !AppConstants.hasSupabaseConfig || ref.watch(guestModeEnabledProvider);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  final mockSession = ref.watch(mockSessionProvider);
  if (mockSession != null) return mockSession;
  if (!AppConstants.hasSupabaseConfig) return null;

  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});
