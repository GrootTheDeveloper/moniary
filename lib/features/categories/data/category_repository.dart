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
    final rows = await _client
        .from('categories')
        .select()
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
    await _client.from('categories').insert({
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
    await _client.from('categories').update({
      'name': name,
      'type': type.value,
      'is_active': isActive,
    }).eq('id', categoryId);
  }
}

