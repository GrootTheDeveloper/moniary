import 'dart:io';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../../application/composer/transaction_composer_controller.dart';

Future<TransactionMutationResult?> showTransactionFormSheet(
  BuildContext context,
  WidgetRef ref, {
  TransactionEntry? initialTransaction,
  DateTime? initialDateTime,
}) {
  return showModalBottomSheet<TransactionMutationResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => TransactionFormScreen(
      initialTransaction: initialTransaction,
      initialDateTime: initialDateTime,
    ),
  );
}

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.initialTransaction,
    this.initialDateTime,
    this.initialImagePath,
  });

  final TransactionEntry? initialTransaction;
  final DateTime? initialDateTime;
  final String? initialImagePath;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final CurrencyTextInputFormatter _amountFormatter;
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

    _amountFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    final initialAmount = transaction?.amount ?? 0;
    _amountController = TextEditingController(
      text: initialAmount > 0
          ? _amountFormatter.formatDouble(initialAmount)
          : '',
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _type = transaction?.type ?? TransactionType.expense;
    _selectedDate =
        transaction?.transactionDate ??
        widget.initialDateTime ??
        DateTime.now();
    _selectedWalletId = transaction?.walletId;
    _selectedCategoryId = transaction?.categoryId;
    if (widget.initialImagePath != null) {
      _pickedFile = XFile(widget.initialImagePath!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setDefaultSelections();
    });
  }

  void _setDefaultSelections() {
    final walletsAsync = ref.read(walletsControllerProvider);
    final categoriesAsync = ref.read(categoriesControllerProvider);

    final allWallets = walletsAsync.asData?.value ?? const <Wallet>[];
    final walletOptions = _isEditing
        ? allWallets
        : allWallets.where((wallet) => wallet.isActive).toList();

    final allCategories = categoriesAsync.asData?.value ?? const <Category>[];
    final categoryOptions = allCategories
        .where(
          (category) =>
              category.type == _type && (_isEditing || category.isActive),
        )
        .toList();

    bool needsUpdate = false;

    if (_selectedWalletId == null && walletOptions.isNotEmpty) {
      _selectedWalletId = walletOptions
          .firstWhere(
            (wallet) => wallet.isDefault,
            orElse: () => walletOptions.first,
          )
          .id;
      needsUpdate = true;
    }

    if (_selectedCategoryId == null && categoryOptions.isNotEmpty) {
      _selectedCategoryId = categoryOptions.first.id;
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {});
    }
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
          (category) =>
              category.type == _type && (_isEditing || category.isActive),
        )
        .toList();

    final canSubmit =
        walletOptions.isNotEmpty &&
        categoryOptions.isNotEmpty &&
        !composerState.isLoading;

    final selectedCategory = allCategories.cast<Category?>().firstWhere(
      (c) => c?.id == _selectedCategoryId,
      orElse: () => null,
    );
    final selectedWallet = allWallets.cast<Wallet?>().firstWhere(
      (w) => w?.id == _selectedWalletId,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: canSubmit ? AppTheme.mint : Colors.grey,
              size: 32,
            ),
            onPressed: canSubmit ? _submit : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _ImagePreview(
              file: _pickedFile,
              onClear: () => setState(() => _pickedFile = null),
              onPick: () => _showImageSourceOptions(context),
            ),
            const SizedBox(height: 24),
            _AmountInput(
              controller: _amountController,
              formatter: _amountFormatter,
            ),
            const SizedBox(height: 16),
            _TypeSelector(
              type: _type,
              onChanged: (newType) {
                setState(() {
                  _type = newType;
                  _selectedCategoryId = null; // Reset category when type changes
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _setDefaultSelections();
                });
              },
            ),
            const SizedBox(height: 24),
            _FormTile(
              label: 'Danh mục',
              value: selectedCategory?.name ?? 'Chọn danh mục',
              icon: Icons.category_outlined,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              leadingWidget: selectedCategory != null
                  ? _CategoryIcon(category: selectedCategory)
                  : null,
              onTap: () => _showCategoryPicker(context, categoryOptions),
            ),
            const SizedBox(height: 12),
            _FormTile(
              label: 'Ví / Tài khoản',
              value: selectedWallet?.name ?? 'Chọn ví',
              icon: Icons.account_balance_wallet_outlined,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              leadingWidget: selectedWallet != null
                  ? _WalletIcon(wallet: selectedWallet)
                  : null,
              onTap: () => _showWalletPicker(context, walletOptions),
            ),
            const SizedBox(height: 12),
            _FormTile(
              label: 'Ngày giờ',
              value: DateFormat(
                'dd/MM/yyyy  HH:mm',
                'vi_VN',
              ).format(_selectedDate),
              icon: Icons.calendar_today_outlined,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 12),
            _NoteInput(controller: _noteController),
            const SizedBox(height: 40),
            if (composerState.isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.mint),
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<Category> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final category = options[index];
          return ListTile(
            leading: _CategoryIcon(category: category),
            title: Text(category.name),
            onTap: () {
              setState(() => _selectedCategoryId = category.id);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showWalletPicker(BuildContext context, List<Wallet> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final wallet = options[index];
          return ListTile(
            leading: _WalletIcon(wallet: wallet),
            title: Text(wallet.name),
            onTap: () {
              setState(() => _selectedWalletId = wallet.id);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
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
    final amount = _amountFormatter.getUnformattedValue().toDouble();

    if (amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Nhập số tiền hợp lệ.')),
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
        await ref
            .read(transactionComposerProvider.notifier)
            .updateTransaction(
              transactionId: widget.initialTransaction!.id,
              amount: amount,
              type: _type,
              walletId: _selectedWalletId!,
              categoryId: _selectedCategoryId!,
              transactionDate: _selectedDate,
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              imageBytes: imageBytes,
            );
      } else {
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

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.file,
    required this.onClear,
    required this.onPick,
  });
  final XFile? file;
  final VoidCallback onClear;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    File(file!.path),
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              if (file != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPick,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Thay đổi ảnh',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountInput extends StatelessWidget {
  const _AmountInput({required this.controller, required this.formatter});
  final TextEditingController controller;
  final CurrencyTextInputFormatter formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Text(
            'Số tiền',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.monetization_on, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [formatter],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('đ', style: TextStyle(fontSize: 20, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.type, required this.onChanged});
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Chi',
              icon: Icons.south_east,
              selected: type == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
              color: AppTheme.mint,
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Thu',
              icon: Icons.north_east,
              selected: type == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
              color: AppTheme.mint,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.color,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.black : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormTile extends StatelessWidget {
  const _FormTile({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.leadingWidget,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final Widget? leadingWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey)),
            ),
            if (leadingWidget != null) ...[
              leadingWidget!,
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _NoteInput extends StatelessWidget {
  const _NoteInput({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          const Text('Ghi chú', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Nhập ghi chú...',
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.clear(),
            child: const Icon(Icons.close, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.fromHex(category.color, fallback: Colors.orange);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(_getIconData(category.icon), color: Colors.white, size: 18),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'payments':
        return Icons.payments;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}

class _WalletIcon extends StatelessWidget {
  const _WalletIcon({required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.fromHex(wallet.color, fallback: Colors.pink);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        _getWalletIconData(wallet.icon),
        color: Colors.white,
        size: 18,
      ),
    );
  }

  IconData _getWalletIconData(String? name) {
    switch (name) {
      case 'wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.credit_card;
    }
  }
}
