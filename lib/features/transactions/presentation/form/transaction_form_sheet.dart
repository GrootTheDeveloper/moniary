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
import '../../../../shared/utils/currency_formatting_ref.dart';
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
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: TransactionFormScreen(
        initialTransaction: initialTransaction,
        initialDateTime: initialDateTime,
      ),
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
  late TextEditingController _amountController;
  late final TextEditingController _noteController;
  late CurrencyTextInputFormatter _amountFormatter;
  bool _formatterInitialized = false;
  late TransactionType _type;
  late DateTime _selectedDate;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  XFile? _pickedFile;
  bool _isOcrExtracting = false;
  bool _hasOcrSuggestions = false;
  late bool _isImportant;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_formatterInitialized) return;
    _formatterInitialized = true;
    final localeName = Localizations.localeOf(context).toString();
    _amountFormatter = CurrencyTextInputFormatter.currency(
      locale: localeName,
      symbol: '',
      decimalDigits: 2,
    );
    final initialAmount = widget.initialTransaction?.amount ?? 0;
    _amountController = TextEditingController(
      text: initialAmount > 0
          ? _amountFormatter.formatDouble(initialAmount)
          : '',
    );
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
            ocrResult.totalAmount!.toDouble(),
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
        _hasOcrSuggestions = true;
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
    final colors = context.moniaryColors;
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
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 393),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      _FormTopButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? context.l10n.transactionEditTitle
                              : context.l10n.transactionCreateTitle,
                          textAlign: TextAlign.center,
                          style: context.moniaryTypography.displaySmall
                              .copyWith(fontSize: 17, height: 1),
                        ),
                      ),
                      _FormTopButton(
                        icon: Icons.check_rounded,
                        tooltip: context.l10n.transactionSaveTransaction,
                        isPrimary: true,
                        isEnabled: canSubmit,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  _ImagePreview(
                    file: _pickedFile,
                    initialImagePath: widget.initialTransaction?.imagePath,
                    amountController: _amountController,
                    amountFormatter: _amountFormatter,
                    noteController: _noteController,
                    onClear: () => setState(() => _pickedFile = null),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FormPillButton(
                          label: context.l10n.transactionChangePhoto,
                          icon: Icons.camera_alt_outlined,
                          onPressed: () => _showImageSourceOptions(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormPillButton(
                          label: _isOcrExtracting
                              ? context.l10n.transactionOcrExtracting
                              : context.l10n.cameraOcrScan,
                          icon: Icons.document_scanner_outlined,
                          foregroundColor: colors.primary,
                          borderColor: colors.primary.withValues(alpha: 0.62),
                          isLoading: _isOcrExtracting,
                          onPressed: _isOcrExtracting
                              ? null
                              : _pickedFile == null
                              ? () => _showImageSourceOptions(context)
                              : _runOcr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                      const SizedBox(width: 10),
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
                          onTap: () =>
                              _showCategoryPicker(context, categoryOptions),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _GridFormTile(
                          label: context.l10n.transactionWallet,
                          value:
                              selectedWallet?.name ??
                              context.l10n.transactionSelectWallet,
                          iconWidget: selectedWallet != null
                              ? _WalletIcon(wallet: selectedWallet)
                              : null,
                          defaultIcon: Icons.account_balance_wallet_outlined,
                          onTap: () =>
                              _showWalletPicker(context, walletOptions),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GridFormTile(
                          label: context.l10n.transactionDateTime,
                          value: DateFormat(
                            'dd/MM · HH:mm',
                            Localizations.localeOf(context).toString(),
                          ).format(_selectedDate),
                          defaultIcon: Icons.calendar_today_outlined,
                          onTap: _pickDateTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ImportantToggle(
                    value: _isImportant,
                    onChanged: (value) {
                      setState(() {
                        _isImportant = value;
                      });
                    },
                  ),
                  if (_hasOcrSuggestions) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.scanSuggestionNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (composerState.isLoading)
                    SizedBox(
                      height: 45,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        child: Text(context.l10n.transactionSaveTransaction),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
      final saveResult = _isEditing
          ? await ref
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
                )
          : await ref
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

      if (!mounted) return;
      if (saveResult.imageUploadFailed) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.transactionImageUploadWarning)),
        );
      }
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

class _ImagePreview extends ConsumerWidget {
  const _ImagePreview({
    required this.file,
    this.initialImagePath,
    required this.amountController,
    required this.amountFormatter,
    required this.noteController,
    required this.onClear,
  });
  final XFile? file;
  final String? initialImagePath;
  final TextEditingController amountController;
  final CurrencyTextInputFormatter amountFormatter;
  final TextEditingController noteController;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return SizedBox(
      width: double.infinity,
      height: 298,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.taupe,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (file != null)
                Image.file(
                  File(file!.path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                )
              else if (initialImagePath != null)
                SupabaseImage(
                  imagePath: initialImagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.image_outlined,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.taupe.withValues(alpha: 0.94),
                        AppTheme.dustyRose.withValues(alpha: 0.52),
                        colors.textPrimary.withValues(alpha: 0.68),
                      ],
                      stops: const [0, 0.62, 1],
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.02),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 19,
                right: 19,
                bottom: 17,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 43,
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
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          hintText: '0',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          suffixText: ref.currencySymbol,
                          suffixStyle: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.46),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: SizedBox(
                        height: 37,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (file != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onClear,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(
                        width: 25,
                        height: 25,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormTopButton extends StatelessWidget {
  const _FormTopButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final activeColor = isPrimary ? colors.success : colors.icon;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? colors.success.withValues(alpha: 0.09)
            : colors.surface.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPrimary
                ? colors.success.withValues(alpha: 0.4)
                : colors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: isPrimary ? 18 : 17,
              color: isEnabled ? activeColor : colors.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _FormPillButton extends StatelessWidget {
  const _FormPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
    this.borderColor,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final effectiveColor = foregroundColor ?? colors.textSecondary;
    final enabled = onPressed != null;
    return Material(
      color: colors.surface.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: (borderColor ?? colors.outline).withValues(
            alpha: enabled ? 1 : 0.56,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 14,
                  color: enabled
                      ? effectiveColor
                      : colors.textDim.withValues(alpha: 0.75),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: enabled
                        ? effectiveColor
                        : colors.textDim.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: FittedBox(
                fit: BoxFit.contain,
                child:
                    iconWidget ??
                    Icon(
                      defaultIcon,
                      color: iconColor ?? colors.textDim,
                      size: 18,
                    ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: colors.textDim,
                      fontSize: 7.2,
                      letterSpacing: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportantToggle extends StatelessWidget {
  const _ImportantToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      height: 47,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.star_border_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              context.l10n.transactionIsImportant,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.84,
            child: Switch(
              value: value,
              activeThumbColor: colors.primary,
              onChanged: onChanged,
            ),
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
    final color = AppColor.fromHex(category.color, fallback: AppTheme.amber);
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
    final color = AppColor.fromHex(wallet.color, fallback: AppTheme.pink);
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
