import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/categories_controller.dart';
import '../../wallets/domain/wallet.dart';
import '../../wallets/presentation/wallets_controller.dart';
import '../domain/transaction_entry.dart';
import '../domain/transaction_mutation_result.dart';
import 'transaction_composer_controller.dart';

Future<TransactionMutationResult?> showTransactionFormSheet(
  BuildContext context,
  WidgetRef ref, {
  TransactionEntry? initialTransaction,
  DateTime? initialDateTime,
}) {
  return showModalBottomSheet<TransactionMutationResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TransactionFormSheet(
      initialTransaction: initialTransaction,
      initialDateTime: initialDateTime,
    ),
  );
}

class _TransactionFormSheet extends ConsumerStatefulWidget {
  const _TransactionFormSheet({
    this.initialTransaction,
    this.initialDateTime,
  });

  final TransactionEntry? initialTransaction;
  final DateTime? initialDateTime;

  @override
  ConsumerState<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<_TransactionFormSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late DateTime _selectedDate;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  XFile? _pickedFile;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    _amountController = TextEditingController(
      text: transaction == null ? '' : transaction.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _type = transaction?.type ?? TransactionType.expense;
    _selectedDate = transaction?.transactionDate ?? widget.initialDateTime ?? DateTime.now();
    _selectedWalletId = transaction?.walletId;
    _selectedCategoryId = transaction?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final composerState = ref.watch(transactionComposerProvider);

    final allWallets = walletsAsync.asData?.value ?? const <Wallet>[];
    final walletOptions = _isEditing
        ? allWallets
        : allWallets.where((wallet) => wallet.isActive).toList();

    final allCategories = categoriesAsync.asData?.value ?? const <Category>[];
    final categoryOptions = allCategories
        .where(
          (category) => category.type == _type && (_isEditing || category.isActive),
        )
        .toList();

    if (_selectedWalletId == null && walletOptions.isNotEmpty) {
      _selectedWalletId = walletOptions.firstWhere(
        (wallet) => wallet.isDefault,
        orElse: () => walletOptions.first,
      ).id;
    }

    if (_selectedCategoryId == null && categoryOptions.isNotEmpty) {
      _selectedCategoryId = categoryOptions.first.id;
    }

    if (_selectedWalletId != null && !walletOptions.any((wallet) => wallet.id == _selectedWalletId)) {
      _selectedWalletId = walletOptions.isEmpty ? null : walletOptions.first.id;
    }

    if (_selectedCategoryId != null &&
        !categoryOptions.any((category) => category.id == _selectedCategoryId)) {
      _selectedCategoryId = categoryOptions.isEmpty ? null : categoryOptions.first.id;
    }

    final canSubmit = walletOptions.isNotEmpty && categoryOptions.isNotEmpty && !composerState.isLoading;

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
                _isEditing ? 'Sua giao dich' : 'Them giao dich',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Luu giao dich kèm ảnh để dễ dàng theo dõi chi tiêu của bạn.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: [
                  _ChoiceChip(
                    label: 'Chi',
                    selected: _type == TransactionType.expense,
                    onTap: () => setState(() => _type = TransactionType.expense),
                  ),
                  _ChoiceChip(
                    label: 'Thu',
                    selected: _type == TransactionType.income,
                    onTap: () => setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ImagePickerPreview(
                file: _pickedFile,
                onPick: () => _showImageSourceOptions(context),
                onClear: () => setState(() => _pickedFile = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'So tien',
                  hintText: '57000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedWalletId,
                items: walletOptions
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: walletOptions.isEmpty
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
                items: categoryOptions
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: categoryOptions.isEmpty
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
                  labelText: 'Ghi chu',
                  hintText: 'Tra sua KOI / Luong freelance / ...',
                  alignLabelWithHint: true,
                ),
              ),
              if (walletsAsync.hasError || categoriesAsync.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  'Khong tai duoc wallet/category. Mo quan ly du lieu de kiem tra.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.danger,
                      ),
                ),
              ],
              if (walletOptions.isEmpty || categoryOptions.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  walletOptions.isEmpty
                      ? 'Ban can it nhat 1 wallet dang hoat dong de tao giao dich.'
                      : 'Ban can it nhat 1 category hop le cho loai giao dich nay.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.amber,
                      ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: Text(
                    composerState.isLoading
                        ? 'Dang luu...'
                        : _isEditing
                            ? 'Cap nhat giao dich'
                            : 'Luu giao dich',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chup anh moi'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chon tu thu vien'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
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
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Nhap so tien hop le.')));
      return;
    }

    if (_selectedWalletId == null || _selectedCategoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chon wallet va category truoc khi luu.')),
      );
      return;
    }

    try {
      Uint8List? imageBytes;
      if (_pickedFile != null) {
        imageBytes = await FlutterImageCompress.compressWithFile(
          _pickedFile!.path,
          quality: 70,
          format: CompressFormat.jpeg,
        );
      }

      final previousDate = widget.initialTransaction?.transactionDate;
      if (_isEditing) {
        await ref.read(transactionComposerProvider.notifier).updateTransaction(
              transactionId: widget.initialTransaction!.id,
              amount: amount,
              type: _type,
              walletId: _selectedWalletId!,
              categoryId: _selectedCategoryId!,
              transactionDate: _selectedDate,
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              imageBytes: imageBytes,
            );
      } else {
        await ref.read(transactionComposerProvider.notifier).createTransaction(
              amount: amount,
              type: _type,
              walletId: _selectedWalletId!,
              categoryId: _selectedCategoryId!,
              transactionDate: _selectedDate,
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              imageBytes: imageBytes,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        TransactionMutationResult(
          previousDate: previousDate,
          currentDate: _selectedDate,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ImagePickerPreview extends StatelessWidget {
  const _ImagePickerPreview({
    required this.file,
    required this.onPick,
    required this.onClear,
  });

  final XFile? file;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined, size: 32, color: Color(0xFF74889A)),
              const SizedBox(height: 8),
              Text(
                'Chụp hoặc chọn ảnh giao dịch',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF74889A),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: FileImage(File(file!.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: onPick,
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
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
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
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
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Nhap so tien hop le.')));
      return;
    }

    if (_selectedWalletId == null || _selectedCategoryId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chon wallet va category truoc khi luu.')),
      );
      return;
    }

    try {
      final previousDate = widget.initialTransaction?.transactionDate;
      if (_isEditing) {
        await ref.read(transactionComposerProvider.notifier).updateTransaction(
              transactionId: widget.initialTransaction!.id,
              amount: amount,
              type: _type,
              walletId: _selectedWalletId!,
              categoryId: _selectedCategoryId!,
              transactionDate: _selectedDate,
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            );
      } else {
        await ref.read(transactionComposerProvider.notifier).createTransaction(
              amount: amount,
              type: _type,
              walletId: _selectedWalletId!,
              categoryId: _selectedCategoryId!,
              transactionDate: _selectedDate,
              note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        TransactionMutationResult(
          previousDate: previousDate,
          currentDate: _selectedDate,
        ),
      );
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
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
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
