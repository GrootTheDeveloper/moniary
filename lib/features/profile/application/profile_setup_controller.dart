import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(currentSessionProvider);
  return ref.watch(profileRepositoryProvider).fetchCurrentProfile();
});

final profileSetupControllerProvider =
    AsyncNotifierProvider<ProfileSetupController, UserProfile?>(
      ProfileSetupController.new,
    );

final paymentQrControllerProvider =
    AsyncNotifierProvider<PaymentQrController, UserProfile?>(
      PaymentQrController.new,
    );

class ProfileSetupController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    ref.watch(currentSessionProvider);
    return ref.watch(profileRepositoryProvider).fetchCurrentProfile();
  }

  Future<void> saveProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? avatarImagePath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .upsertProfile(
            fullName: fullName,
            username: username,
            timezone: timezone,
            avatarImagePath: avatarImagePath,
          ),
    );
    ref.invalidate(currentProfileProvider);
    // Invalidate the controller to ensure next build gets fresh data
    ref.invalidateSelf();
  }
}

class PaymentQrController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    ref.watch(currentSessionProvider);
    return ref.watch(profileRepositoryProvider).fetchCurrentProfile();
  }

  Future<void> save(String imagePath) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).savePaymentQrImage(imagePath),
    );
    ref.invalidate(currentProfileProvider);
  }

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).clearPaymentQrImage(),
    );
    ref.invalidate(currentProfileProvider);
  }
}
