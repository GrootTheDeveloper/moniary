import 'dart:typed_data';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../calendar/application/month/calendar_month_provider.dart';
import '../../categories/application/categories_controller.dart';
import '../../categories/domain/models/category.dart';
import '../../transactions/application/composer/transaction_composer_controller.dart';
import '../../transactions/domain/models/transaction_mutation_result.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/domain/models/wallet.dart';
import '../domain/ocr_result.dart';

class OcrReviewArgs {
  const OcrReviewArgs({required this.result, required this.imagePath});

  final OcrResult result;
  final String imagePath;
}

class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({required this.args, super.key});

  static const routePath = '/ocr-review';

  final OcrReviewArgs args;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _date;
  String? _walletId;
  String? _categoryId;
  bool _merchantEdited = false;
  bool _amountEdited = false;
  bool _dateEdited = false;
  bool _categoryEdited = false;
  bool _noteEdited = false;
  bool _resolvedCategorySuggestion = false;

  @override
  void initState() {
    super.initState();
    final result = widget.args.result;
    _merchantController = TextEditingController(
      text: result.merchantName ?? '',
    );
    _amountController = TextEditingController(
      text: result.totalAmount?.toString() ?? '',
    );
    _noteController = TextEditingController(text: result.note ?? '');
    _date = result.transactionDate ?? DateTime.now();
    _merchantController.addListener(_markMerchantEdited);
    _amountController.addListener(_markAmountEdited);
    _noteController.addListener(_markNoteEdited);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final composer = ref.watch(transactionComposerProvider);

    final wallets =
        walletsAsync.asData?.value
            .where((wallet) => wallet.isActive)
            .toList() ??
        const <Wallet>[];
    final categories =
        categoriesAsync.asData?.value
            .where(
              (category) =>
                  category.isActive && category.type == TransactionType.expense,
            )
            .toList() ??
        const <Category>[];
    _walletId ??= _defaultWalletId(wallets);
    if (!_resolvedCategorySuggestion && categories.isNotEmpty) {
      final suggestedCategoryId = _suggestedCategoryId(
        categories,
        widget.args.result.categoryKey,
      );
      _categoryId = suggestedCategoryId ?? categories.first.id;
      if (widget.args.result.categorySuggestion != null &&
          suggestedCategoryId == null) {
        _categoryEdited = true;
      }
      _resolvedCategorySuggestion = true;
    }

    final loading = composer.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanReviewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SuggestionNotice(),
          const SizedBox(height: 18),
          TextField(
            controller: _merchantController,
            decoration: InputDecoration(
              labelText: context.l10n.scanMerchant,
              prefixIcon: const Icon(Icons.storefront_outlined),
              helperText: _suggestionLabel(
                widget.args.result.merchantSuggestion,
                edited: _merchantEdited,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.transactionAmount,
              suffixText: ref.currencySymbol,
              prefixIcon: const Icon(Icons.payments_outlined),
              helperText: _suggestionLabel(
                widget.args.result.totalSuggestion,
                edited: _amountEdited,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DateTile(
            date: _date,
            onTap: _pickDate,
            suggestionLabel: _suggestionLabel(
              widget.args.result.dateSuggestion,
              edited: _dateEdited,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: wallets.any((wallet) => wallet.id == _walletId)
                ? _walletId
                : null,
            isExpanded: true,
            items: wallets
                .map(
                  (wallet) => DropdownMenuItem(
                    value: wallet.id,
                    child: Text(wallet.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: loading
                ? null
                : (value) => setState(() => _walletId = value),
            decoration: InputDecoration(
              labelText: context.l10n.transactionWalletAccount,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
                categories.any((category) => category.id == _categoryId)
                ? _categoryId
                : null,
            isExpanded: true,
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: loading
                ? null
                : (value) => setState(() {
                    _categoryId = value;
                    _categoryEdited = true;
                  }),
            decoration: InputDecoration(
              labelText: context.l10n.transactionExpenseCategory,
              prefixIcon: const Icon(Icons.category_outlined),
              helperText: _suggestionLabel(
                widget.args.result.categorySuggestion,
                edited: _categoryEdited,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n.transactionNote,
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes_outlined),
              helperText: _suggestionLabel(
                widget.args.result.noteSuggestion,
                edited: _noteEdited,
              ),
            ),
          ),
          if (walletsAsync.isLoading || categoriesAsync.isLoading) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(color: AppTheme.mint),
            const SizedBox(height: 8),
            Text(context.l10n.transactionLoadingWalletCategory),
          ],
          if (widget.args.result.items.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              context.l10n.scanItemsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.args.result.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: item.quantity == null
                    ? null
                    : Text(
                        context.l10n.scanQuantity(
                          _formatDecimal(item.quantity!),
                        ),
                      ),
                trailing: item.price == null
                    ? null
                    : Text(ref.formatAmount(item.price!)),
              ),
            ),
          ],
          if (walletsAsync.hasError || categoriesAsync.hasError) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.transactionWalletCategoryError,
              style: const TextStyle(color: AppTheme.danger),
            ),
          ] else if (wallets.isEmpty || categories.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              context.l10n.transactionWalletCategoryRequired,
              style: const TextStyle(color: AppTheme.amber),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading || wallets.isEmpty || categories.isEmpty
                ? null
                : _save,
            child: Text(
              loading
                  ? context.l10n.transactionSaving
                  : context.l10n.transactionSaveTransaction,
            ),
          ),
        ],
      ),
    );
  }

  String? _defaultWalletId(List<Wallet> wallets) {
    if (wallets.isEmpty) {
      return null;
    }
    return wallets
        .firstWhere((wallet) => wallet.isDefault, orElse: () => wallets.first)
        .id;
  }

  String? _suggestedCategoryId(List<Category> categories, String? categoryKey) {
    if (categoryKey == null) return null;
    final expectedIcon = switch (categoryKey) {
      'food' => 'restaurant',
      'transport' => 'directions_car',
      'shopping' => 'shopping_bag',
      _ => null,
    };
    if (expectedIcon == null) return null;
    for (final category in categories) {
      if (category.icon == expectedIcon) return category.id;
    }
    return null;
  }

  String? _suggestionLabel<T>(
    OcrSuggestion<T>? suggestion, {
    required bool edited,
  }) {
    if (suggestion == null || edited) return null;
    return suggestion.needsReview
        ? context.l10n.scanSuggestionNeedsReview
        : context.l10n.scanAiSuggestion;
  }

  void _markMerchantEdited() => _markEdited(
    isEdited: _merchantEdited,
    update: () => _merchantEdited = true,
  );

  void _markAmountEdited() =>
      _markEdited(isEdited: _amountEdited, update: () => _amountEdited = true);

  void _markNoteEdited() =>
      _markEdited(isEdited: _noteEdited, update: () => _noteEdited = true);

  void _markEdited({required bool isEdited, required VoidCallback update}) {
    if (isEdited || !mounted) return;
    setState(update);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _dateEdited = true;
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = _parseDecimalAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.transactionAmountPositive)),
      );
      return;
    }
    if (_walletId == null || _categoryId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.transactionSelectWalletCategory)),
      );
      return;
    }

    try {
      final Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        widget.args.imagePath,
        quality: AppConstants.imageCompressQuality,
        format: CompressFormat.jpeg,
      );
      await ref
          .read(transactionComposerProvider.notifier)
          .createTransaction(
            amount: amount,
            type: TransactionType.expense,
            walletId: _walletId!,
            categoryId: _categoryId!,
            transactionDate: _date,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            merchantName: _merchantController.text.trim().isEmpty
                ? null
                : _merchantController.text.trim(),
            source: 'ocr',
            imageBytes: bytes,
          );
      if (!mounted) {
        return;
      }
      ref.invalidate(
        calendarMonthProvider(DateTime(_date.year, _date.month, 1)),
      );
      context.pop(TransactionMutationResult(currentDate: _date));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save OCR transaction', error, stackTrace);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.transactionSaveError(
              userFriendlyMessage(context, error),
            ),
          ),
        ),
      );
    }
  }

  String _formatDecimal(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double? _parseDecimalAmount(String input) {
    final value = input.trim().replaceAll(RegExp(r'\s'), '');
    if (value.isEmpty) {
      return null;
    }

    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      final decimalIndex = lastDot > lastComma ? lastDot : lastComma;
      final decimalSeparator = value[decimalIndex];
      final thousandsSeparator = decimalSeparator == '.' ? ',' : '.';
      return double.tryParse(
        value
            .replaceAll(thousandsSeparator, '')
            .replaceFirst(decimalSeparator, '.'),
      );
    }

    final separator = lastDot >= 0 ? '.' : (lastComma >= 0 ? ',' : null);
    if (separator == null) {
      return double.tryParse(value);
    }

    final parts = value.split(separator);
    final isThousands =
        parts.length > 2 || (parts.length == 2 && parts.last.length == 3);
    return double.tryParse(isThousands ? parts.join() : parts.join('.'));
  }
}

class _SuggestionNotice extends StatelessWidget {
  const _SuggestionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.scanSuggestionNotice,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.date,
    required this.onTap,
    this.suggestionLabel,
  });

  final DateTime date;
  final VoidCallback onTap;
  final String? suggestionLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.outline),
      ),
      tileColor: AppTheme.surfaceRaised,
      leading: const Icon(Icons.event_outlined),
      title: Text(context.l10n.transactionDate),
      subtitle: suggestionLabel == null ? null : Text(suggestionLabel!),
      trailing: Text(
        DateFormat(
          'dd/MM/yyyy',
          Localizations.localeOf(context).toString(),
        ).format(date),
      ),
    );
  }
}
