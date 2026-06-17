import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../core/constants/app_color.dart';
import '../../../categories/domain/models/category.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../scanning/application/scanning_controller.dart';
import '../../../wallets/domain/models/wallet.dart';
import '../../../wallets/application/wallets_controller.dart';
import '../../domain/models/transaction_entry.dart';
import '../../domain/models/transaction_mutation_result.dart';
import '../../application/composer/transaction_composer_controller.dart';
import '../../../../shared/widgets/supabase_image.dart';

Future<TransactionMutationResult?> showTransactionFormSheet(
  BuildContext context,
  WidgetRef ref, {
  TransactionEntry? initialTransaction,
  DateTime? initialDateTime,
}) {
  return showModalBottomSheet<TransactionMutationResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
  bool _isOcrExtracting = false;
  late bool _isImportant;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;

    _amountFormatter = CurrencyTextInputFormatter.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 2,
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
    _isImportant = transaction?.isImportant ?? false;
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

  Future<void> _runOcr() async {
    if (_pickedFile == null) return;
    setState(() {
      _isOcrExtracting = true;
    });

    try {
      final ocrResult = await ref
          .read(ocrExtractionControllerProvider)
          .extractFromImage(_pickedFile!.path);

      if (!mounted) return;

      setState(() {
        if (ocrResult.totalAmount != null) {
          _amountController.text = _amountFormatter.formatDouble(
            ocrResult.totalAmount!,
          );
        }
        if (ocrResult.note != null) {
          _noteController.text = ocrResult.note!;
        } else if (ocrResult.merchantName != null) {
          _noteController.text = ocrResult.merchantName!;
        }
        if (ocrResult.transactionDate != null) {
          _selectedDate = ocrResult.transactionDate!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.transactionOcrSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to extract OCR data in transaction form',
        error,
        stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage(context, error)),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOcrExtracting = false;
        });
      }
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

    if ((_selectedCategoryId == null && categoryOptions.isNotEmpty) ||
        (_selectedWalletId == null && walletOptions.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setDefaultSelections();
      });
    }

    final canSubmit =
        _selectedWalletId != null &&
        _selectedCategoryId != null &&
        !composerState.isLoading &&
        !_isOcrExtracting;

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing
              ? context.l10n.transactionEditTitle
              : context.l10n.transactionCreateTitle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_circle_outline,
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
              initialImagePath: widget.initialTransaction?.imagePath,
              amountController: _amountController,
              amountFormatter: _amountFormatter,
              noteController: _noteController,
              onClear: () => setState(() => _pickedFile = null),
              onPick: () => _showImageSourceOptions(context),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 12),
              if (_isOcrExtracting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.mint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.transactionOcrExtracting,
                          style: const TextStyle(
                            color: AppTheme.mint,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(
                              color: Colors.white54,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => _showImageSourceOptions(context),
                          icon: const Icon(Icons.camera_alt_outlined, size: 20),
                          label: Text(context.l10n.transactionChangePhoto),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mint,
                            side: const BorderSide(
                              color: AppTheme.mint,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: _runOcr,
                          icon: const Icon(
                            Icons.document_scanner_outlined,
                            size: 20,
                          ),
                          label: Text(
                            context.l10n.cameraOcrScan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white54, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: () => _showImageSourceOptions(context),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: Text(context.l10n.transactionChangePhoto),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _GridFormTile(
                    label: context.l10n.transactionType,
                    value: _type == TransactionType.expense
                        ? context.l10n.categoryExpense
                        : context.l10n.categoryIncome,
                    defaultIcon: _type == TransactionType.expense
                        ? Icons.south_east
                        : Icons.north_east,
                    iconColor: _type == TransactionType.expense
                        ? AppTheme.danger
                        : AppTheme.success,
                    onTap: () {
                      setState(() {
                        _type = _type == TransactionType.expense
                            ? TransactionType.income
                            : TransactionType.expense;
                        _selectedCategoryId = null;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _setDefaultSelections();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GridFormTile(
                    label: context.l10n.transactionCategory,
                    value:
                        selectedCategory?.name ??
                        context.l10n.transactionSelectCategory,
                    iconWidget: selectedCategory != null
                        ? _CategoryIcon(category: selectedCategory)
                        : null,
                    defaultIcon: Icons.category_outlined,
                    onTap: () => _showCategoryPicker(context, categoryOptions),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GridFormTile(
                    label: context.l10n.transactionWalletAccount,
                    value:
                        selectedWallet?.name ??
                        context.l10n.transactionSelectWallet,
                    iconWidget: selectedWallet != null
                        ? _WalletIcon(wallet: selectedWallet)
                        : null,
                    defaultIcon: Icons.account_balance_wallet_outlined,
                    onTap: () => _showWalletPicker(context, walletOptions),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GridFormTile(
                    label: context.l10n.transactionDateTime,
                    value: DateFormat(
                      'dd/MM/yyyy',
                      Localizations.localeOf(context).toString(),
                    ).format(_selectedDate),
                    defaultIcon: Icons.calendar_today_outlined,
                    onTap: _pickDateTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_outline,
                    color: Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.transactionIsImportant,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Switch(
                    value: _isImportant,
                    activeThumbColor: AppTheme.mint,
                    onChanged: (value) {
                      setState(() {
                        _isImportant = value;
                      });
                    },
                  ),
                ],
              ),
            ),
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
              title: Text(context.l10n.scanTakePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(context.l10n.scanChooseGallery),
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
        SnackBar(content: Text(context.l10n.transactionAmountInvalid)),
      );
      return;
    }

    try {
      Uint8List? imageBytes;
      if (_pickedFile != null) {
        imageBytes = await FlutterImageCompress.compressWithFile(
          _pickedFile!.path,
          quality: AppConstants.imageCompressQuality,
          format: CompressFormat.jpeg,
        );
        imageBytes ??= await _pickedFile!.readAsBytes();
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
              isImportant: _isImportant,
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
              isImportant: _isImportant,
            );
      }

      if (!mounted) return;
      context.pop(
        TransactionMutationResult(
          previousDate: previousDate,
          currentDate: _selectedDate,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.file,
    this.initialImagePath,
    required this.amountController,
    required this.amountFormatter,
    required this.noteController,
    required this.onClear,
    required this.onPick,
  });
  final XFile? file;
  final String? initialImagePath;
  final TextEditingController amountController;
  final CurrencyTextInputFormatter amountFormatter;
  final TextEditingController noteController;
  final VoidCallback onClear;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            width: double.infinity,
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
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else if (initialImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SupabaseImage(
                      imagePath: initialImagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fallbackIcon: Icons.image_outlined,
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                // Gradient Overlay + Inputs
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      top: 48,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Amount Input
                        SizedBox(
                          height: 56,
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              amountFormatter,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white54),
                              suffixText: context.l10n.transactionAmountSuffix,
                              suffixStyle: const TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Note Input
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: noteController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(27),
                            ],
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              filled: false,
                              hintText: context.l10n.transactionEnterNote,
                              hintStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 20,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
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
        ),
      ],
    );
  }
}

class _GridFormTile extends StatelessWidget {
  const _GridFormTile({
    required this.label,
    required this.value,
    this.iconWidget,
    this.defaultIcon,
    this.iconColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Widget? iconWidget;
  final IconData? defaultIcon;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(defaultIcon, color: iconColor ?? Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(_getIconData(category.icon), color: color, size: 18),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'payments':
        return Icons.payments_outlined;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.category_outlined;
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(_getWalletIconData(wallet.icon), color: color, size: 18),
    );
  }

  IconData _getWalletIconData(String? name) {
    switch (name) {
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.credit_card_outlined;
    }
  }
}
