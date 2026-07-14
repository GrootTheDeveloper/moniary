import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(supabaseClientProvider),
    useMockData: ref.watch(useMockDataModeProvider),
  );
});

class CategoryRepository {
  CategoryRepository(this._client, {bool useMockData = false})
    : _useMockData = useMockData || !AppConstants.hasSupabaseConfig;

  final SupabaseClient _client;
  final bool _useMockData;

  static List<Category> get mockCategories => _mockCategories;

  static final List<Category> _mockCategories = [
    Category(
      id: 'mock-cat-food',
      name: 'Ăn uống',
      type: TransactionType.expense,
      icon: 'restaurant',
      color: '#F6B24D',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-transport',
      name: 'Đi lại',
      type: TransactionType.expense,
      icon: 'directions_car',
      color: '#2563EB',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-shopping',
      name: 'Mua sắm',
      type: TransactionType.expense,
      icon: 'shopping_bag',
      color: '#E45CA6',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Category(
      id: 'mock-cat-salary',
      name: 'Lương',
      type: TransactionType.income,
      icon: 'attach_money',
      color: '#44D884',
      isDefault: true,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  void clearMockUserData() {
    if (_useMockData) _mockCategories.clear();
  }

  Future<void> ensureOccupationDefaults(String occupation) async {
    if (_useMockData) {
      for (final template in _occupationTemplates(occupation)) {
        _upsertMockDefaultCategory(template);
      }
      return;
    }

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
    if (_useMockData) {
      return _mockCategories.where((c) => c.isActive).toList();
    }
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
    if (_useMockData) {
      _mockCategories.add(
        Category(
          id: 'mock-cat-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          type: type,
          icon: type == TransactionType.income ? 'add' : 'remove',
          color: '#9CB0C2',
          isDefault: false,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
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

  static List<_CategoryTemplate> _occupationTemplates(String occupation) {
    final common = <_CategoryTemplate>[
      const _CategoryTemplate(
        name: 'Ăn uống',
        type: TransactionType.expense,
        icon: 'restaurant',
        color: '#FF7043',
      ),
      const _CategoryTemplate(
        name: 'Di chuyển',
        type: TransactionType.expense,
        icon: 'directions_bus',
        color: '#42A5F5',
      ),
      const _CategoryTemplate(
        name: 'Mua sắm',
        type: TransactionType.expense,
        icon: 'shopping_bag',
        color: '#AB47BC',
      ),
      const _CategoryTemplate(
        name: 'Hóa đơn',
        type: TransactionType.expense,
        icon: 'receipt_long',
        color: '#FFA726',
      ),
      const _CategoryTemplate(
        name: 'Lương',
        type: TransactionType.income,
        icon: 'payments',
        color: '#66BB6A',
      ),
      const _CategoryTemplate(
        name: 'Thưởng',
        type: TransactionType.income,
        icon: 'savings',
        color: '#26A69A',
      ),
      const _CategoryTemplate(
        name: 'Khác',
        type: TransactionType.income,
        icon: 'more_horiz',
        color: '#78909C',
      ),
    ];

    final tailored = switch (occupation) {
      'student' => const <_CategoryTemplate>[
        _CategoryTemplate(
          name: 'Học phí',
          type: TransactionType.expense,
          icon: 'school',
          color: '#5C6BC0',
        ),
        _CategoryTemplate(
          name: 'Sách vở',
          type: TransactionType.expense,
          icon: 'menu_book',
          color: '#8D6E63',
        ),
        _CategoryTemplate(
          name: 'Nhà trọ',
          type: TransactionType.expense,
          icon: 'home',
          color: '#26A69A',
        ),
        _CategoryTemplate(
          name: 'Sinh hoạt phí',
          type: TransactionType.expense,
          icon: 'local_laundry_service',
          color: '#7E57C2',
        ),
      ],
      'office_worker' => const <_CategoryTemplate>[
        _CategoryTemplate(
          name: 'Cà phê',
          type: TransactionType.expense,
          icon: 'coffee',
          color: '#8D6E63',
        ),
        _CategoryTemplate(
          name: 'Gia đình',
          type: TransactionType.expense,
          icon: 'family_restroom',
          color: '#EC407A',
        ),
        _CategoryTemplate(
          name: 'Sức khỏe',
          type: TransactionType.expense,
          icon: 'health_and_safety',
          color: '#26A69A',
        ),
      ],
      'freelancer' => const <_CategoryTemplate>[
        _CategoryTemplate(
          name: 'Công cụ làm việc',
          type: TransactionType.expense,
          icon: 'laptop_mac',
          color: '#5C6BC0',
        ),
        _CategoryTemplate(
          name: 'Internet',
          type: TransactionType.expense,
          icon: 'wifi',
          color: '#29B6F6',
        ),
        _CategoryTemplate(
          name: 'Không gian làm việc',
          type: TransactionType.expense,
          icon: 'desk',
          color: '#8D6E63',
        ),
        _CategoryTemplate(
          name: 'Thu nhập dự án',
          type: TransactionType.income,
          icon: 'work_outline',
          color: '#43A047',
        ),
      ],
      'business_owner' => const <_CategoryTemplate>[
        _CategoryTemplate(
          name: 'Nhập hàng',
          type: TransactionType.expense,
          icon: 'inventory_2',
          color: '#7E57C2',
        ),
        _CategoryTemplate(
          name: 'Mặt bằng',
          type: TransactionType.expense,
          icon: 'storefront',
          color: '#26A69A',
        ),
        _CategoryTemplate(
          name: 'Marketing',
          type: TransactionType.expense,
          icon: 'campaign',
          color: '#EC407A',
        ),
        _CategoryTemplate(
          name: 'Vận chuyển',
          type: TransactionType.expense,
          icon: 'local_shipping',
          color: '#42A5F5',
        ),
        _CategoryTemplate(
          name: 'Tiếp khách',
          type: TransactionType.expense,
          icon: 'groups',
          color: '#FF7043',
        ),
        _CategoryTemplate(
          name: 'Doanh thu',
          type: TransactionType.income,
          icon: 'point_of_sale',
          color: '#43A047',
        ),
      ],
      _ => const <_CategoryTemplate>[],
    };

    return [...common, ...tailored];
  }

  static void _upsertMockDefaultCategory(_CategoryTemplate template) {
    final index = _mockCategories.indexWhere(
      (category) =>
          category.type == template.type &&
          category.name.toLowerCase() == template.name.toLowerCase(),
    );

    final category = Category(
      id: index == -1 ? _mockCategoryId(template) : _mockCategories[index].id,
      name: template.name,
      type: template.type,
      icon: template.icon,
      color: template.color,
      isDefault: true,
      isActive: true,
      createdAt: index == -1
          ? DateTime.now()
          : _mockCategories[index].createdAt,
    );

    if (index == -1) {
      _mockCategories.add(category);
    } else {
      _mockCategories[index] = category;
    }
  }

  static String _mockCategoryId(_CategoryTemplate template) {
    final slug = template.name
        .toLowerCase()
        .codeUnits
        .map((unit) => unit.toRadixString(16))
        .join();
    return 'mock-cat-${template.type.value}-$slug';
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required TransactionType type,
    required bool isActive,
  }) async {
    if (_useMockData) {
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

class _CategoryTemplate {
  const _CategoryTemplate({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String name;
  final TransactionType type;
  final String icon;
  final String color;
}
