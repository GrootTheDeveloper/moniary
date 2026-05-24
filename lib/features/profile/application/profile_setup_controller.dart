import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.watch(profileRepositoryProvider).fetchCurrentProfile();
});

final profileSetupControllerProvider =
    AsyncNotifierProvider<ProfileSetupController, UserProfile?>(
  ProfileSetupController.new,
);

class ProfileSetupController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    return ref.read(profileRepositoryProvider).fetchCurrentProfile();
  }

  Future<void> saveProfile({
    required String fullName,
    required String timezone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).upsertProfile(
            fullName: fullName,
            timezone: timezone,
          ),
    );
    ref.invalidate(currentProfileProvider);
  }
}
