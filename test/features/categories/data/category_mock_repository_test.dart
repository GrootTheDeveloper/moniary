import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';

void main() {
  test('mock repository provides selectable expense categories', () async {
    final repository = CategoryRepository.mock();

    final categories = await repository.fetchCategories();
    final expenses = categories.where(
      (category) =>
          category.type == TransactionType.expense && category.isActive,
    );

    expect(expenses, isNotEmpty);
    expect(expenses.map((category) => category.name), contains('Ăn uống'));
    expect(expenses.map((category) => category.name), contains('Di chuyển'));
  });

  test('mock repository preserves create and update operations', () async {
    final repository = CategoryRepository.mock();

    await repository.createCategory(
      name: 'Thú cưng',
      type: TransactionType.expense,
    );
    final created = (await repository.fetchCategories()).singleWhere(
      (category) => category.name == 'Thú cưng',
    );

    await repository.updateCategory(
      categoryId: created.id,
      name: 'Chăm sóc thú cưng',
      type: TransactionType.expense,
      isActive: false,
    );
    final updated = (await repository.fetchCategories()).singleWhere(
      (category) => category.id == created.id,
    );

    expect(updated.name, 'Chăm sóc thú cưng');
    expect(updated.isActive, isFalse);
  });
}
