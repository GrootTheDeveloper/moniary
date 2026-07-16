import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(supabaseClientProvider));
});

class WalletRepository {
  WalletRepository(this._client);

  final SupabaseClient _client;

  Future<List<Wallet>> fetchWallets() async {
    final session = _client.auth.currentSession;
    if (session == null) return [];

    try {
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
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> createWallet({
    required String name,
    required WalletType type,
    required double initialBalance,
    bool isDefault = false,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client.rpc(
        'create_personal_wallet',
        params: {
          'p_name': name,
          'p_type': type.value,
          'p_initial_balance': initialBalance,
          'p_is_default': isDefault,
        },
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateWallet({
    required String walletId,
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isDefault,
    required bool isActive,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client.rpc(
        'update_personal_wallet',
        params: {
          'p_wallet_id': walletId,
          'p_name': name,
          'p_type': type.value,
          'p_initial_balance': initialBalance,
          'p_is_default': isDefault,
          'p_is_active': isActive,
        },
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }
}
