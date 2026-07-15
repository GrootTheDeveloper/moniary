import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../domain/facebook_account_link.dart';

final pendingFacebookAccountLinkProvider =
    NotifierProvider<
      PendingFacebookAccountLinkNotifier,
      PendingFacebookAccountLink?
    >(PendingFacebookAccountLinkNotifier.new);

class PendingFacebookAccountLinkNotifier
    extends Notifier<PendingFacebookAccountLink?> {
  static const _userIdKey = 'pending_facebook_account_link_user_id';

  @override
  PendingFacebookAccountLink? build() {
    final userId = ref.read(sharedPreferencesProvider).getString(_userIdKey);
    return userId == null ? null : PendingFacebookAccountLink(userId: userId);
  }

  Future<void> save(String userId) async {
    state = PendingFacebookAccountLink(userId: userId);
    await ref.read(sharedPreferencesProvider).setString(_userIdKey, userId);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_userIdKey);
  }
}
