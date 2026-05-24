import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile?> fetchCurrentProfile() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', session.user.id)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<UserProfile> upsertProfile({
    required String fullName,
    required String timezone,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Ban chua dang nhap.');
    }

    final row = await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'timezone': timezone,
        })
        .eq('id', session.user.id)
        .select()
        .single();

    return UserProfile.fromMap(row);
  }
}
