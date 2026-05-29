import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  static List<Category> get mockCategories => _mockCategories;

  static final List<Category> _mockCategories = [
    Category(
      id: 'mock-cat-food',
      name: 'Ăn uống',
      type: TransactionType.expense,
      icon: 'restaurant',
      color: '#FF9800',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-transport',
      name: 'Đi lại',
      type: TransactionType.expense,
      icon: 'directions_car',
      color: '#2196F3',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-shopping',
      name: 'Mua sắm',
      type: TransactionType.expense,
      icon: 'shopping_bag',
      color: '#E91E63',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-salary',
      name: 'Lương',
      type: TransactionType.income,
      icon: 'attach_money',
      color: '#4CAF50',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  Future<List<Category>> fetchCategories() async {
    if (!AppConstants.hasSupabaseConfig) {
      return _mockCategories.where((c) => c.isActive).toList();
    }
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
    if (!AppConstants.hasSupabaseConfig) {
      _mockCategories.add(
        Category(
          id: 'mock-cat-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          type: type,
          icon: type == TransactionType.income ? 'add' : 'remove',
          color: '#9E9E9E',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('Bạn chưa đăng nhập.');

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
    if (!AppConstants.hasSupabaseConfig) {
      final index = _mockCategories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        _mockCategories[index] = Category(
          id: categoryId,
          name: name,
          type: type,
          icon: _mockCategories[index].icon,
          color: _mockCategories[index].color,
          isDefault: _mockCategories[index].isDefault,
          isActive: isActive,
          createdAt: _mockCategories[index].createdAt,
        );
      }
      return;
    }
    final session = _client.auth.currentSession;
    if (session == null) throw const AppException('Bạn chưa đăng nhập.');

    await _client
        .from('categories')
        .update({'name': name, 'type': type.value, 'is_active': isActive})
        .eq('id', categoryId)
        .eq('user_id', session.user.id);
  }
}
