import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/models/wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(supabaseClientProvider));
});

class WalletRepository {
  WalletRepository(this._client);

  final SupabaseClient _client;

  static List<Wallet> get mockWallets => _mockWallets;

  static final List<Wallet> _mockWallets = [
    Wallet(
      id: 'mock-wallet-cash',
      name: 'Tiền mặt',
      type: WalletType.cash,
      icon: 'wallet',
      color: '#4CAF50',
      initialBalance: 2000000,
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Wallet(
      id: 'mock-wallet-momo',
      name: 'Ví Momo',
      type: WalletType.ewallet,
      icon: 'payment',
      color: '#E91E63',
      initialBalance: 1000000,
      isDefault: false,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  Future<List<Wallet>> fetchWallets() async {
    if (!AppConstants.hasSupabaseConfig) {
      return _mockWallets.where((w) => w.isActive).toList();
    }
    final session = _client.auth.currentSession;
    if (session == null) return [];

    final rows = await _client
        .from('wallets')
        .select()
        .eq('user_id', session.user.id)
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
    if (!AppConstants.hasSupabaseConfig) {
      if (isDefault) {
        for (var i = 0; i < _mockWallets.length; i++) {
          _mockWallets[i] = Wallet(
            id: _mockWallets[i].id,
            name: _mockWallets[i].name,
            type: _mockWallets[i].type,
            icon: _mockWallets[i].icon,
            color: _mockWallets[i].color,
            initialBalance: _mockWallets[i].initialBalance,
            isDefault: false,
            isActive: _mockWallets[i].isActive,
            createdAt: _mockWallets[i].createdAt,
          );
        }
      }
      _mockWallets.add(
        Wallet(
          id: 'mock-wallet-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          type: type,
          icon: 'wallet',
          color: '#9C27B0',
          initialBalance: initialBalance,
          isDefault: isDefault,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('Bạn chưa đăng nhập.');

    if (isDefault) {
      await _clearDefaultWallets(userId: session.user.id);
    }

    await _client.from('wallets').insert({
      'user_id': session.user.id,
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
    if (!AppConstants.hasSupabaseConfig) {
      if (isDefault) {
        for (var i = 0; i < _mockWallets.length; i++) {
          if (_mockWallets[i].id != walletId) {
            _mockWallets[i] = Wallet(
              id: _mockWallets[i].id,
              name: _mockWallets[i].name,
              type: _mockWallets[i].type,
              icon: _mockWallets[i].icon,
              color: _mockWallets[i].color,
              initialBalance: _mockWallets[i].initialBalance,
              isDefault: false,
              isActive: _mockWallets[i].isActive,
              createdAt: _mockWallets[i].createdAt,
            );
          }
        }
      }
      final index = _mockWallets.indexWhere((w) => w.id == walletId);
      if (index != -1) {
        _mockWallets[index] = Wallet(
          id: walletId,
          name: name,
          type: type,
          icon: _mockWallets[index].icon,
          color: _mockWallets[index].color,
          initialBalance: initialBalance,
          isDefault: isDefault,
          isActive: isActive,
          createdAt: _mockWallets[index].createdAt,
        );
      }
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('Bạn chưa đăng nhập.');

    if (isDefault) {
      await _clearDefaultWallets(
        userId: session.user.id,
        exceptWalletId: walletId,
      );
    }

    await _client
        .from('wallets')
        .update({
          'name': name,
          'type': type.value,
          'initial_balance': initialBalance,
          'is_default': isDefault,
          'is_active': isActive,
        })
        .eq('id', walletId)
        .eq('user_id', session.user.id);
  }

  Future<void> _clearDefaultWallets({
    required String userId,
    String? exceptWalletId,
  }) async {
    var query = _client.from('wallets').update({'is_default': false});
    if (exceptWalletId != null) {
      query = query.neq('id', exceptWalletId);
    }
    await query.eq('user_id', userId).eq('is_default', true);
  }
}
