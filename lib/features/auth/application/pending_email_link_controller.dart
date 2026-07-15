import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';
import '../domain/email_account_link.dart';

final pendingEmailAccountLinkProvider =
    NotifierProvider<PendingEmailAccountLinkNotifier, PendingEmailAccountLink?>(
      PendingEmailAccountLinkNotifier.new,
    );

class PendingEmailAccountLinkNotifier
    extends Notifier<PendingEmailAccountLink?> {
  static const _userIdKey = 'pending_email_account_link_user_id';
  static const _emailKey = 'pending_email_account_link_email';

  @override
  PendingEmailAccountLink? build() {
    final preferences = ref.read(sharedPreferencesProvider);
    final userId = preferences.getString(_userIdKey);
    final email = preferences.getString(_emailKey);
    if (userId == null || email == null) return null;
    return PendingEmailAccountLink(userId: userId, email: email);
  }

  Future<void> save({required String userId, required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    state = PendingEmailAccountLink(userId: userId, email: normalizedEmail);
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_userIdKey, userId);
    await preferences.setString(_emailKey, normalizedEmail);
  }

  Future<void> clear() async {
    state = null;
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.remove(_userIdKey);
    await preferences.remove(_emailKey);
  }
}
