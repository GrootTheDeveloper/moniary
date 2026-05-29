import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_color.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../l10n/l10n_extension.dart';
import '../domain/models/category.dart';
import '../application/categories_controller.dart';

class CategorySection extends ConsumerWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.categoryTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCategoryForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.commonAdd),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.categoryDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Text(context.l10n.categoryEmpty);
                  }

                  final expense = categories
                      .where(
                        (category) => category.type == TransactionType.expense,
                      )
                      .toList();
                  final income = categories
                      .where(
                        (category) => category.type == TransactionType.income,
                      )
                      .toList();

                  return Column(
                    children: [
                      _CategoryGroup(
                        title: context.l10n.categoryExpense,
                        categories: expense,
                      ),
                      const SizedBox(height: 12),
                      _CategoryGroup(
                        title: context.l10n.categoryIncome,
                        categories: income,
                      ),
                    ],
                  );
                },
                error: (error, stackTrace) =>
                    Text(context.l10n.categoryError(error.toString())),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGroup extends ConsumerWidget {
  const _CategoryGroup({required this.title, required this.categories});

  final String title;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          Text(context.l10n.categoryNoData)
        else
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryTile(
                category: category,
                onEdit: () =>
                    _showCategoryForm(context, ref, category: category),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onEdit});

  final Category category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.fromHex(
      category.color,
      fallback: const Color(0xFF4EA1FF),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          child: const Icon(Icons.label_outline),
        ),
        title: Row(
          children: [
            Expanded(child: Text(category.name)),
            if (category.isDefault)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(label: Text(context.l10n.walletDefault)),
              ),
          ],
        ),
        subtitle: Text(
          category.isActive
              ? context.l10n.walletActive
              : context.l10n.walletInactive,
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

Future<void> _showCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  Category? category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CategoryFormSheet(category: category),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  const _CategoryFormSheet({this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late TransactionType _selectedType;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? TransactionType.expense;
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.category != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? context.l10n.categoryEditTitle
                  : context.l10n.categoryCreateTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: context.l10n.categoryName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionType>(
              initialValue: _selectedType,
              items: TransactionType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == TransactionType.expense
                            ? context.l10n.categoryExpense
                            : context.l10n.categoryIncome,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
              decoration: InputDecoration(labelText: context.l10n.categoryType),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: Text(context.l10n.categoryActivated),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? context.l10n.categorySaving
                    : context.l10n.categorySave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.categoryNameRequired)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = ref.read(categoriesControllerProvider.notifier);
      if (widget.category == null) {
        await controller.createCategory(name: name, type: _selectedType);
      } else {
        await controller.updateCategory(
          categoryId: widget.category!.id,
          name: name,
          type: _selectedType,
          isActive: _isActive,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}
