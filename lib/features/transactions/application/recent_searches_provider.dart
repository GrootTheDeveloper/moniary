import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/preferences_providers.dart';

/// Persisted list of the user's recent transaction searches, most recent first.
final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _key = 'recent_transaction_searches';
  static const _maxEntries = 8;

  @override
  List<String> build() {
    return ref.read(sharedPreferencesProvider).getStringList(_key) ??
        const <String>[];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final lower = trimmed.toLowerCase();
    final next = <String>[
      trimmed,
      ...state.where((entry) => entry.toLowerCase() != lower),
    ];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    state = next;
    await ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }

  Future<void> remove(String query) async {
    state = state.where((entry) => entry != query).toList();
    await ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  Future<void> clear() async {
    state = const <String>[];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}
