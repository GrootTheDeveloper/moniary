import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../settings/data/account/account_repository.dart';

final accountStatusControllerProvider =
    AsyncNotifierProvider<AccountStatusController, bool>(
      AccountStatusController.new,
    );

class AccountStatusController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    if (!AppConstants.hasSupabaseConfig) return false;

    final client = ref.watch(supabaseClientProvider);
    final session = client.auth.currentSession;
    if (session == null) return false;

    final res = await client
        .from('profiles')
        .select('deleted_at')
        .eq('id', session.user.id)
        .maybeSingle();

    if (res == null || res['deleted_at'] == null) {
      return false;
    }
    return true;
  }

  Future<void> restoreAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).restoreAccount();
      return false;
    });
  }
}
