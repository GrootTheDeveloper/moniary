import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<Category>> fetchCategories() async {
    final session = _client.auth.currentSession;
    if (session == null) return [];

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
  }

  Future<void> createCategory({
    required String name,
    required TransactionType type,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

    await _client.from('categories').insert({
      'user_id': session.user.id,
      'name': name,
      'type': type.value,
    });
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required TransactionType type,
    required bool isActive,
  }) async {
    final session = _client.auth.currentSession;
    if (session == null) throw Exception('Ban chua dang nhap');

    await _client.from('categories').update({
      'name': name,
      'type': type.value,
      'is_active': isActive,
    }).eq('id', categoryId).eq('user_id', session.user.id);
  }
}

