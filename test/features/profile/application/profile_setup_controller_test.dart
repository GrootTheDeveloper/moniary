import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:moniary/features/profile/data/profile_repository.dart';
import 'package:moniary/features/profile/domain/profile_update_result.dart';
import 'package:moniary/features/profile/domain/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({this.saveError}) : super(_FakeSupabaseClient());

  final Object? saveError;
  var saveCount = 0;
  String? savedEmail;

  static const profile = UserProfile(
    id: 'user-id',
    fullName: 'Bruce',
    email: 'old@example.com',
    avatarUrl: 'avatars/user-id/avatar_old.jpg',
    loginProvider: 'email',
    timezone: 'Asia/Ho_Chi_Minh',
    username: 'bruce',
  );

  @override
  Future<UserProfile?> fetchCurrentProfile() async => profile;

  @override
  Future<ProfileUpdateResult> upsertProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? email,
    String? avatarImagePath,
  }) async {
    saveCount++;
    savedEmail = email;
    final error = saveError;
    if (error != null) throw error;
    return const ProfileUpdateResult(
      profile: profile,
      pendingEmail: 'new@example.com',
    );
  }
}

void main() {
  test('saveProfile returns pending email result and saves once', () async {
    final repository = _FakeProfileRepository();
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        currentSessionProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await container.read(profileSetupControllerProvider.future);

    final result = await container
        .read(profileSetupControllerProvider.notifier)
        .saveProfile(
          fullName: 'Bruce',
          username: 'bruce',
          timezone: 'Asia/Ho_Chi_Minh',
          email: 'new@example.com',
        );

    expect(repository.saveCount, 1);
    expect(repository.savedEmail, 'new@example.com');
    expect(result.pendingEmail, 'new@example.com');
    expect(container.read(profileSetupControllerProvider).hasError, isFalse);
  });

  test(
    'saveProfile rethrows repository errors and exposes error state',
    () async {
      const failure = AppException(
        'Avatar upload failed',
        code: 'AVATAR_UPLOAD_FAILED',
      );
      final repository = _FakeProfileRepository(saveError: failure);
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
          currentSessionProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await container.read(profileSetupControllerProvider.future);

      await expectLater(
        container
            .read(profileSetupControllerProvider.notifier)
            .saveProfile(
              fullName: 'Bruce',
              username: 'bruce',
              timezone: 'Asia/Ho_Chi_Minh',
            ),
        throwsA(same(failure)),
      );

      expect(repository.saveCount, 1);
      expect(container.read(profileSetupControllerProvider).hasError, isTrue);
    },
  );
}
