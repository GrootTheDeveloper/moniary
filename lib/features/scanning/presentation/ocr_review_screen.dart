import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
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
          : result.totalAmount!.round().toString(),
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
      appBar: AppBar(title: const Text('Kiểm tra hóa đơn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ConfidenceCard(confidence: widget.args.result.confidence),
          const SizedBox(height: 18),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Cửa hàng',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Số tiền',
              suffixText: 'đ',
              prefixIcon: Icon(Icons.payments_outlined),
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
            decoration: const InputDecoration(
              labelText: 'Ví / Tài khoản',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
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
            decoration: const InputDecoration(
              labelText: 'Danh mục chi',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          if (walletsAsync.isLoading || categoriesAsync.isLoading) ...[
            const SizedBox(height: 18),
            const LinearProgressIndicator(color: AppTheme.mint),
            const SizedBox(height: 8),
            const Text('Đang tải ví và danh mục...'),
          ],
          if (widget.args.result.items.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Mục nhận diện',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.args.result.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: item.quantity == null
                    ? null
                    : Text('Số lượng: ${item.quantity}'),
                trailing: item.price == null ? null : Text(_money(item.price!)),
              ),
            ),
          ],
          if (walletsAsync.hasError || categoriesAsync.hasError) ...[
            const SizedBox(height: 14),
            const Text(
              'Không tải được ví hoặc danh mục. Vui lòng thử lại.',
              style: TextStyle(color: AppTheme.danger),
            ),
          ] else if (wallets.isEmpty || categories.isEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Cần có ví và danh mục chi đang hoạt động trước khi lưu.',
              style: TextStyle(color: AppTheme.amber),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: loading || wallets.isEmpty || categories.isEmpty
                ? null
                : _save,
            child: Text(loading ? 'Đang lưu...' : 'Lưu giao dịch'),
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
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll('.', '').replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nhập số tiền lớn hơn 0.')),
      );
      return;
    }
    if (_walletId == null || _categoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chọn ví và danh mục trước khi lưu.')),
      );
      return;
    }

    try {
      final Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        widget.args.imagePath,
        quality: 70,
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
      Navigator.of(context).pop(TransactionMutationResult(currentDate: _date));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không lưu được giao dịch: $error')),
      );
    }
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
              'Độ tin cậy OCR: $percent%. Hãy kiểm tra thông tin trước khi lưu.',
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
      title: const Text('Ngày giao dịch'),
      trailing: Text(DateFormat('dd/MM/yyyy', 'vi_VN').format(date)),
    );
  }
}

String _money(double amount) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(amount);
}
