import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../../categories/application/categories_controller.dart';
import '../../wallets/application/wallets_controller.dart';
import '../application/profile_setup_controller.dart';
import '../data/profile_repository.dart';

final profileSurveyControllerProvider =
    AsyncNotifierProvider<ProfileSurveyController, void>(
      ProfileSurveyController.new,
    );

class ProfileSurveyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> complete({
    required String occupation,
    required String preferredCurrency,
    required String walletName,
    required double initialBalance,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .completeSurveySetup(
            occupation: occupation,
            preferredCurrency: preferredCurrency,
            walletName: walletName,
            initialBalance: initialBalance,
          );

      await ref
          .read(preferredCurrencyProvider.notifier)
          .setCurrency(preferredCurrency);

      ref
        ..invalidate(currentProfileProvider)
        ..invalidate(walletsControllerProvider)
        ..invalidate(categoriesControllerProvider);
    });
  }
}
