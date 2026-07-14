import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../domain/google_account_link.dart';

final pendingGoogleAccountLinkProvider =
    NotifierProvider<
      PendingGoogleAccountLinkNotifier,
      PendingGoogleAccountLink?
    >(PendingGoogleAccountLinkNotifier.new);

final accountLinkNoticeProvider =
    NotifierProvider<AccountLinkNoticeNotifier, AccountLinkNotice?>(
      AccountLinkNoticeNotifier.new,
    );

class PendingGoogleAccountLinkNotifier
    extends Notifier<PendingGoogleAccountLink?> {
  static const _userIdKey = 'pending_google_account_link_user_id';

  @override
  PendingGoogleAccountLink? build() {
    final userId = ref.read(sharedPreferencesProvider).getString(_userIdKey);
    return userId == null ? null : PendingGoogleAccountLink(userId: userId);
  }

  Future<void> save(String userId) async {
    state = PendingGoogleAccountLink(userId: userId);
    await ref.read(sharedPreferencesProvider).setString(_userIdKey, userId);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_userIdKey);
  }
}

class AccountLinkNoticeNotifier extends Notifier<AccountLinkNotice?> {
  @override
  AccountLinkNotice? build() => null;

  void show(AccountLinkNotice notice) => state = notice;

  void clear() => state = null;
}
