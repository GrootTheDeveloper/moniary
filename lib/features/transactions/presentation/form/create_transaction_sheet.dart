import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../application/composer/transaction_composer_controller.dart';

Future<DateTime?> showCreateTransactionSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CreateTransactionSheet(),
  );
}

class _CreateTransactionSheet extends ConsumerStatefulWidget {
  const _CreateTransactionSheet();

  @override
  ConsumerState<_CreateTransactionSheet> createState() =>
      _CreateTransactionSheetState();
}

class _CreateTransactionSheetState
    extends ConsumerState<_CreateTransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final composerState = ref.watch(transactionComposerProvider);

    final wallets =
        walletsAsync.asData?.value
            .where((wallet) => wallet.isActive)
            .toList() ??
        const <Wallet>[];
    final categories =
        categoriesAsync.asData?.value
            .where((category) => category.isActive && category.type == _type)
            .toList() ??
        const <Category>[];

    _selectedWalletId ??= wallets.isNotEmpty
        ? (wallets.firstWhere(
            (wallet) => wallet.isDefault,
            orElse: () => wallets.first,
          )).id
        : null;

    if (categories.isNotEmpty &&
        !categories.any((category) => category.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.first.id;
    }

    final canSubmit =
        wallets.isNotEmpty && categories.isNotEmpty && !composerState.isLoading;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Thêm giao dịch',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Lưu giao dịch trước, phần ảnh sẽ được thêm ở bước tiếp theo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: [
                  _ChoiceChip(
                    label: 'Chi',
                    selected: _type == TransactionType.expense,
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                  ),
                  _ChoiceChip(
                    label: 'Thu',
                    selected: _type == TransactionType.income,
                    onTap: () => setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  hintText: '57000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedWalletId,
                items: wallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: wallets.isEmpty
                    ? null
                    : (value) => setState(() => _selectedWalletId = value),
                decoration: const InputDecoration(
                  labelText: 'Wallet',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: categories.isEmpty
                    ? null
                    : (value) => setState(() => _selectedCategoryId = value),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 14),
              _DateTimeTile(value: _selectedDate, onTap: _pickDateTime),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Tra sua KOI / Luong freelance / ...',
                  alignLabelWithHint: true,
                ),
              ),
              if (walletsAsync.hasError || categoriesAsync.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  'Không tải được wallet/category. Mở quản lý dữ liệu để kiểm tra.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
                ),
              ],
              if (wallets.isEmpty || categories.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  wallets.isEmpty
                      ? 'Bạn cần ít nhất 1 wallet đang hoạt động để tạo giao dịch.'
                      : 'Bạn cần ít nhất 1 category đang hoạt động cho loại giao dịch này.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.amber),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: Text(
                  composerState.isLoading ? 'Đang lưu...' : 'Lưu giao dịch',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nhập số tiền hợp lệ.')),
      );
      return;
    }

    if (_selectedWalletId == null || _selectedCategoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chọn wallet và category trước khi lưu.')),
      );
      return;
    }

    try {
      await ref
          .read(transactionComposerProvider.notifier)
          .createTransaction(
            amount: amount,
            type: _type,
            walletId: _selectedWalletId!,
            categoryId: _selectedCategoryId!,
            transactionDate: _selectedDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(_selectedDate);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy • HH:mm', 'vi_VN').format(value),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.mint : AppTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.mint : AppTheme.outline,
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
