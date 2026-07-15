import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  Future<void> ensureOccupationDefaults(String occupation) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client.rpc(
        'ensure_occupation_categories',
        params: {'p_occupation': occupation},
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('Failed to initialize occupation categories', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Failed to initialize occupation categories', e, st);
      throw const AppException(
        'errorConnection',
        code: 'CATEGORY_INITIALIZATION_FAILED',
      );
    }
  }

  Future<List<Category>> fetchCategories() async {
    final session = _client.auth.currentSession;
    if (session == null) return [];

    try {
      final rows = await _client
          .from('categories')
          .select()
          .eq('user_id', session.user.id)
          .order('type')
          .order('is_default', ascending: false)
          .order('created_at');

      return (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Category.fromMap)
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

  Future<void> createCategory({
    required String name,
    required TransactionType type,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client.from('categories').insert({
        'user_id': session.user.id,
        'name': name,
        'type': type.value,
      });
    } on PostgrestException catch (e, st) {
      AppLogger.error('Lỗi cơ sở dữ liệu', e, st);
      throw AppException(e.message, code: e.code);
    } catch (e, st) {
      if (e is AppException) rethrow;
      AppLogger.error('Lỗi kết nối', e, st);
      throw const AppException('errorConnection');
    }
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required TransactionType type,
    required bool isActive,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await _client
          .from('categories')
          .update({'name': name, 'type': type.value, 'is_active': isActive})
          .eq('id', categoryId)
          .eq('user_id', session.user.id);
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
