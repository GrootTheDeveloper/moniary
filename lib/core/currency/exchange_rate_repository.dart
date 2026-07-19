import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/utils/app_logger.dart';
import '../../shared/utils/exchange_rates.dart';
import '../supabase/app_exception.dart';
import '../supabase/supabase_providers.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository(ref.watch(supabaseClientProvider));
});

/// Loads the full exchange_rates table once per session. Rates are not
/// user-scoped data (public reference data behind RLS's read-all policy),
/// so this repository has no mock branch — it always reads the real table,
/// even for guest sessions.
final exchangeRatesProvider = FutureProvider<ExchangeRates>((ref) async {
  final entries = await ref.watch(exchangeRateRepositoryProvider).fetchAll();
  return ExchangeRates(entries);
});

class ExchangeRateRepository {
  ExchangeRateRepository(this._client);

  final SupabaseClient _client;

  Future<List<ExchangeRateEntry>> fetchAll() async {
    try {
      final rows = await _client.from('exchange_rates').select();
      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ExchangeRateEntry.fromMap)
          .toList(growable: false);
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
