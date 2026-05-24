import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(supabaseClientProvider));
});

class WalletRepository {
  WalletRepository(this._client);

  final SupabaseClient _client;

  Future<List<Wallet>> fetchWallets() async {
    final rows = await _client
        .from('wallets')
        .select()
        .order('is_default', ascending: false)
        .order('created_at');

    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Wallet.fromMap)
        .toList();
  }

  Future<void> createWallet({
    required String name,
    required WalletType type,
    required double initialBalance,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await _clearDefaultWallets();
    }

    await _client.from('wallets').insert({
      'name': name,
      'type': type.value,
      'initial_balance': initialBalance,
      'is_default': isDefault,
    });
  }

  Future<void> updateWallet({
    required String walletId,
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isDefault,
    required bool isActive,
  }) async {
    if (isDefault) {
      await _clearDefaultWallets(exceptWalletId: walletId);
    }

    await _client.from('wallets').update({
      'name': name,
      'type': type.value,
      'initial_balance': initialBalance,
      'is_default': isDefault,
      'is_active': isActive,
    }).eq('id', walletId);
  }

  Future<void> _clearDefaultWallets({String? exceptWalletId}) async {
    var query = _client.from('wallets').update({'is_default': false});
    if (exceptWalletId != null) {
      query = query.neq('id', exceptWalletId);
    }
    await query.eq('is_default', true);
  }
}

