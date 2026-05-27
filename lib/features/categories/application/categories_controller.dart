import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/category_repository.dart';
import '../domain/models/category.dart';

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
      CategoriesController.new,
    );

class CategoriesController extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() {
    return ref.read(categoryRepositoryProvider).fetchCategories();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoryRepositoryProvider).fetchCategories(),
    );
  }

  Future<void> createCategory({
    required String name,
    required TransactionType type,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(categoryRepositoryProvider)
          .createCategory(name: name, type: type);
      state = AsyncData(
        await ref.read(categoryRepositoryProvider).fetchCategories(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required TransactionType type,
    required bool isActive,
  }) async {
    state = const AsyncLoading();

    try {
      await ref
          .read(categoryRepositoryProvider)
          .updateCategory(
            categoryId: categoryId,
            name: name,
            type: type,
            isActive: isActive,
          );
      state = AsyncData(
        await ref.read(categoryRepositoryProvider).fetchCategories(),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
