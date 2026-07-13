import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../l10n/l10n_extension.dart';
import '../domain/models/category.dart';
import '../application/categories_controller.dart';

class CategorySection extends ConsumerWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final colors = context.moniaryColors;

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionToolbar(
                countLabel: '0 ${context.l10n.manageDataCategoryCountLabel}',
                onAdd: () => _showCategoryForm(context, ref),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.categoryEmpty,
                style: TextStyle(color: colors.textDim),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionToolbar(
              countLabel:
                  '${categories.length} ${context.l10n.manageDataCategoryCountLabel}',
              onAdd: () => _showCategoryForm(context, ref),
            ),
            const SizedBox(height: 10),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _CategoryTile(
                  category: category,
                  onEdit: () =>
                      _showCategoryForm(context, ref, category: category),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) {
        AppLogger.error('Failed to load categories section', error, stackTrace);
        return Text(
          context.l10n.categoryError(userFriendlyMessage(context, error)),
          style: TextStyle(color: colors.danger),
        );
      },
      loading: () => LinearProgressIndicator(
        minHeight: 2,
        color: colors.primary,
        backgroundColor: colors.outline.withValues(alpha: 0.35),
      ),
    );
  }
}

class _SectionToolbar extends StatelessWidget {
  const _SectionToolbar({required this.countLabel, required this.onAdd});

  final String countLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: colors.textDim,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              '+ ${context.l10n.commonAdd}',
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: colors.primary,
                fontSize: 11,
                letterSpacing: 0,
              ),
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
    final colors = context.moniaryColors;
    final color = AppColor.fromHex(category.color, fallback: colors.primary);

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 9, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIconData(category.icon),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                      ),
                      if (category.isDefault) ...[
                        const SizedBox(width: 8),
                        _DefaultBadge(label: context.l10n.walletDefault),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${category.type == TransactionType.expense ? context.l10n.categoryExpense : context.l10n.categoryIncome} · ${category.isActive ? context.l10n.walletActive : context.l10n.walletInactive}'
                        .toUpperCase(),
                    style: context.moniaryTypography.metadata.copyWith(
                      color: colors.textDim,
                      fontSize: 8.5,
                      letterSpacing: 1.1,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: colors.textSecondary,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.categoryEditTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: colors.success,
          fontSize: 7,
          letterSpacing: 0.5,
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
    useSafeArea: true,
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

      context.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}

IconData _categoryIconData(String? name) {
  return switch (name) {
    'restaurant' => Icons.restaurant_outlined,
    'directions_car' => Icons.directions_car_outlined,
    'shopping_bag' => Icons.shopping_bag_outlined,
    'attach_money' => Icons.payments_outlined,
    _ => Icons.category_outlined,
  };
}
