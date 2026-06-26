import 'dart:typed_data';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/utils/currency_formatter.dart';
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

  @override
  void initState() {
    super.initState();
    final result = widget.args.result;
    _merchantController = TextEditingController(
      text: result.merchantName ?? '',
    );
    _amountController = TextEditingController(
      text: result.totalAmount == null
          ? ''
          : _formatDecimal(result.totalAmount!),
    );
    _noteController = TextEditingController(text: result.note ?? '');
    _date = result.transactionDate ?? DateTime.now();
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
    _categoryId ??= categories.isEmpty ? null : categories.first.id;

    final loading = composer.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanReviewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ConfidenceCard(confidence: widget.args.result.confidence),
          const SizedBox(height: 18),
          TextField(
            controller: _merchantController,
            decoration: InputDecoration(
              labelText: context.l10n.scanMerchant,
              prefixIcon: const Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.transactionAmount,
              suffixText: context.l10n.transactionAmountSuffix,
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: wallets.any((wallet) => wallet.id == _walletId)
                ? _walletId
                : null,
            items: wallets
                .map(
                  (wallet) => DropdownMenuItem(
                    value: wallet.id,
                    child: Text(wallet.name),
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
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: loading
                ? null
                : (value) => setState(() => _categoryId = value),
            decoration: InputDecoration(
              labelText: context.l10n.transactionExpenseCategory,
              prefixIcon: const Icon(Icons.category_outlined),
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
                    : Text(formatVnd(item.price!)),
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

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_outlined, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.scanOcrConfidence(percent),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

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
      trailing: Text(
        DateFormat(
          'dd/MM/yyyy',
          Localizations.localeOf(context).toString(),
        ).format(date),
      ),
    );
  }
}
