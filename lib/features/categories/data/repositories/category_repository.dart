import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  ref.watch(currentSessionProvider);
  if (ref.watch(useMockDataModeProvider)) {
    return CategoryRepository.mock();
  }
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

class CategoryRepository {
  CategoryRepository(SupabaseClient client)
    : _client = client,
      _mockCategories = null;

  CategoryRepository.mock()
    : _client = null,
      _mockCategories = _defaultMockCategories();

  final SupabaseClient? _client;
  final List<Category>? _mockCategories;
  var _mockSequence = 0;

  bool get _usesMockData => _mockCategories != null;

  Future<void> ensureOccupationDefaults(String occupation) async {
    if (_usesMockData) return;
    final client = _client!;
    final session = client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await client.rpc(
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
    if (_usesMockData) {
      return List<Category>.unmodifiable(_mockCategories!);
    }
    final client = _client!;
    final session = client.auth.currentSession;
    if (session == null) return [];

    try {
      final rows = await client
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
    if (_usesMockData) {
      _mockCategories!.add(
        Category(
          id: 'mock-category-custom-${_mockSequence++}',
          name: name.trim(),
          type: type,
          icon: type == TransactionType.expense ? 'category' : 'attach_money',
          color: type == TransactionType.expense ? '#78909C' : '#43A047',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
    final client = _client!;
    final session = client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await client.from('categories').insert({
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
    if (_usesMockData) {
      final index = _mockCategories!.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index < 0) {
        throw const AppException('Category not found', code: 'NOT_FOUND');
      }
      final current = _mockCategories[index];
      _mockCategories[index] = Category(
        id: current.id,
        name: name.trim(),
        type: type,
        icon: current.icon,
        color: current.color,
        isDefault: current.isDefault,
        isActive: isActive,
        createdAt: current.createdAt,
      );
      return;
    }
    final client = _client!;
    final session = client.auth.currentSession;
    if (session == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }

    try {
      await client
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

  static List<Category> _defaultMockCategories() {
    final createdAt = DateTime.utc(2026);
    return [
      Category(
        id: 'mock-category-food',
        name: 'Ăn uống',
        type: TransactionType.expense,
        icon: 'restaurant',
        color: '#FF7043',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
      Category(
        id: 'mock-category-transport',
        name: 'Di chuyển',
        type: TransactionType.expense,
        icon: 'directions_car',
        color: '#42A5F5',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
      Category(
        id: 'mock-category-shopping',
        name: 'Mua sắm',
        type: TransactionType.expense,
        icon: 'shopping_bag',
        color: '#AB47BC',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
      Category(
        id: 'mock-category-home',
        name: 'Nhà ở',
        type: TransactionType.expense,
        icon: 'home',
        color: '#26A69A',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
      Category(
        id: 'mock-category-entertainment',
        name: 'Giải trí',
        type: TransactionType.expense,
        icon: 'movie',
        color: '#EC407A',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
      Category(
        id: 'mock-category-income',
        name: 'Thu nhập',
        type: TransactionType.income,
        icon: 'attach_money',
        color: '#43A047',
        isDefault: true,
        isActive: true,
        createdAt: createdAt,
      ),
    ];
  }
}
