import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

void main() {
  late CategoryRepository repository;

  setUp(() {
    repository = CategoryRepository(_FakeSupabaseClient(), useMockData: true);
    repository.clearMockUserData();
  });

  tearDown(() {
    repository.clearMockUserData();
  });

  test(
    'ensureOccupationDefaults adds student-specific mock categories',
    () async {
      await repository.ensureOccupationDefaults('student');

      final categories = await repository.fetchCategories();
      final names = categories.map((category) => category.name).toSet();

      expect(names, containsAll(['Ăn uống', 'Học phí', 'Sách vở', 'Nhà trọ']));
      expect(
        categories
            .where(
              (category) =>
                  category.name == 'Học phí' &&
                  category.type == TransactionType.expense &&
                  category.isDefault &&
                  category.isActive,
            )
            .length,
        1,
      );
    },
  );

  test('ensureOccupationDefaults is idempotent for mock categories', () async {
    await repository.ensureOccupationDefaults('business_owner');
    await repository.ensureOccupationDefaults('business_owner');

    final categories = await repository.fetchCategories();
    final businessRevenueCategories = categories.where(
      (category) =>
          category.name == 'Doanh thu' &&
          category.type == TransactionType.income,
    );

    expect(businessRevenueCategories, hasLength(1));
  });
}
