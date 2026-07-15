import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../categories/domain/models/category.dart';
import '../../../scanning/application/scanning_controller.dart';
import '../../../scanning/domain/ocr_result.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/services/group_split_calculator.dart';
import '../widgets/group_confirmation_dialog.dart';
import '../widgets/payer_amount_input_list.dart';
import '../widgets/payment_mode_selector.dart';
import '../widgets/participant_selector.dart';
import '../widgets/split_mode_selector.dart';

class AddGroupTransactionArgs {
  const AddGroupTransactionArgs({required this.groupId, this.initialDetail});

  final String groupId;
  final GroupTransactionDetail? initialDetail;
}

class AddGroupTransactionScreen extends ConsumerStatefulWidget {
  const AddGroupTransactionScreen({required this.args, super.key});

  static const routePath = '/groups/transaction/form';

  final AddGroupTransactionArgs args;

  @override
  ConsumerState<AddGroupTransactionScreen> createState() =>
      _AddGroupTransactionScreenState();
}

class _AddGroupTransactionScreenState
    extends ConsumerState<AddGroupTransactionScreen> {
  final _amountController = TextEditingController();
  final _captionController = TextEditingController();
  final _noteController = TextEditingController();
  final _rateController = TextEditingController(text: '1');
  final Map<String, TextEditingController> _payerControllers = {};
  final Map<String, TextEditingController> _shareControllers = {};
  final Set<String> _selectedPayerIds = {};
  final Set<String> _selectedParticipantIds = {};
  GroupSplitMode _splitMode = GroupSplitMode.equal;
  GroupPaymentMode _paymentMode = GroupPaymentMode.everyonePaid;
  String? _categoryId;
  String? _categoryName;
  String _currencyCode = 'VND';
  String? _imageFilePath;
  List<OcrLineItem> _ocrItems = const [];
  String? _ocrCategoryKey;
  bool _participantsInitialized = false;
  bool _ocrLoading = false;
  bool _hasOcrSuggestions = false;
  bool _currencyInitialized = false;

  bool get _editing => widget.args.initialDetail != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.args.initialDetail;
    if (initial != null) {
      final transaction = initial.transaction;
      _amountController.text = transaction.totalAmount.toString();
      _currencyCode = transaction.currencyCode;
      _rateController.text = transaction.exchangeRateToBase.toString();
      _captionController.text = transaction.caption ?? '';
      _noteController.text = transaction.note ?? '';
      _splitMode = transaction.splitMode;
      _paymentMode = transaction.paymentMode;
      _categoryId = transaction.categoryId;
      _categoryName = transaction.categoryName;
      for (final payer in initial.payers) {
        _selectedPayerIds.add(payer.userId);
        _payerControllers[payer.userId] = TextEditingController(
          text: (payer.paidAmount / transaction.exchangeRateToBase)
              .round()
              .toString(),
        );
      }
      for (final share in initial.shares) {
        _selectedParticipantIds.add(share.userId);
        _shareControllers[share.userId] = TextEditingController(
          text: (share.shareAmount / transaction.exchangeRateToBase)
              .round()
              .toString(),
        );
      }
      _participantsInitialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _captionController.dispose();
    _noteController.dispose();
    _rateController.dispose();
    for (final controller in _payerControllers.values) {
      controller.dispose();
    }
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailProvider(widget.args.groupId));
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final action = ref.watch(groupActionControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing
              ? context.l10n.expenseFormEditTitle
              : context.l10n.groupAddTransaction,
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (detail) {
          if (!_currencyInitialized) {
            _currencyInitialized = true;
            if (!_editing) _currencyCode = detail.group.baseCurrency;
          }
          _ensureMemberControllers(detail.activeMembers);
          _resolveOcrCategory(categoriesAsync.asData?.value ?? const []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              _ImagePickerCard(
                localPath: _imageFilePath,
                storagePath: widget.args.initialDetail?.transaction.imagePath,
                onPick: _pickImage,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.groupTransactionImageOptional,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_ocrLoading) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ] else if (_hasOcrSuggestions) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.l10n.scanSuggestionNotice)),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.groupTransactionTotal,
                  suffixText: ref.currencySymbol,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currencyCode,
                decoration: InputDecoration(
                  labelText: context.l10n.groupTransactionCurrency,
                  helperText: context.l10n.groupTransactionCurrencySubtitle(
                    detail.group.baseCurrency,
                  ),
                ),
                items:
                    {
                          detail.group.baseCurrency,
                          'VND',
                          'USD',
                          'EUR',
                          'SGD',
                          'JPY',
                        }
                        .map(
                          (code) =>
                              DropdownMenuItem(value: code, child: Text(code)),
                        )
                        .toList(),
                onChanged: (value) => setState(
                  () => _currencyCode = value ?? detail.group.baseCurrency,
                ),
              ),
              if (_currencyCode != detail.group.baseCurrency) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.groupTransactionExchangeRate,
                    helperText: context.l10n
                        .groupTransactionExchangeRateSubtitle(
                          _currencyCode,
                          detail.group.baseCurrency,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(context.l10n.groupActionFailed),
                data: (categories) {
                  final expenseCategories = categories
                      .where(
                        (category) => category.type == TransactionType.expense,
                      )
                      .toList();
                  return DropdownButtonFormField<String>(
                    initialValue:
                        expenseCategories.any(
                          (category) => category.id == _categoryId,
                        )
                        ? _categoryId
                        : null,
                    isExpanded: true,
                    items: expenseCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final selected = expenseCategories.where(
                        (category) => category.id == value,
                      );
                      setState(() {
                        _categoryId = value;
                        _categoryName = selected.isEmpty
                            ? null
                            : selected.first.name;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: context.l10n.groupTransactionCategory,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: context.l10n.groupTransactionCaption,
                  prefixIcon: const Icon(Icons.short_text_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.groupTransactionNote,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ParticipantSelector(
                members: detail.activeMembers,
                selectedIds: _selectedParticipantIds,
                onChanged: (selectedIds) => setState(() {
                  _selectedParticipantIds
                    ..clear()
                    ..addAll(selectedIds);
                }),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.groupSplitModeTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SplitModeSelector(
                value: _splitMode,
                onChanged: (value) => setState(() => _splitMode = value),
                onHelp: () => _showSplitModeGuide(context),
              ),
              if (_splitMode == GroupSplitMode.exact) ...[
                const SizedBox(height: 18),
                ExactShareInputList(
                  members: detail.activeMembers,
                  selectedIds: _selectedParticipantIds,
                  controllers: _shareControllers,
                ),
              ],
              if (_ocrItems.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  context.l10n.scanItemsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final item in _ocrItems)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    trailing: item.price == null
                        ? null
                        : Text(ref.formatAmount(item.price!)),
                  ),
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.groupPaymentModeTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              PaymentModeSelector(
                value: _paymentMode,
                onChanged: (value) {
                  setState(() {
                    _paymentMode = value;
                    _selectedPayerIds.clear();
                  });
                },
              ),
              PayerAmountInputList(
                members: detail.activeMembers,
                paymentMode: _paymentMode,
                selectedPayerIds: _selectedPayerIds,
                controllers: _payerControllers,
                onSingleSelected: (userId) => setState(
                  () => _selectedPayerIds
                    ..clear()
                    ..add(userId),
                ),
                onMultipleToggled: (userId, selected) {
                  setState(() {
                    if (selected) {
                      _selectedPayerIds.add(userId);
                    } else {
                      _selectedPayerIds.remove(userId);
                    }
                  });
                },
              ),
              if (_splitMode == GroupSplitMode.unequal) ...[
                const SizedBox(height: 12),
                _Notice(text: context.l10n.groupTransactionPendingAmounts),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('post-group-transaction'),
                onPressed: action.isLoading
                    ? null
                    : () => _confirmAndSave(detail.activeMembers),
                child: Text(
                  action.isLoading
                      ? context.l10n.groupPosting
                      : context.l10n.groupPost,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ensureMemberControllers(List<SpendingGroupMember> members) {
    for (final member in members) {
      _payerControllers.putIfAbsent(member.userId, TextEditingController.new);
      _shareControllers.putIfAbsent(member.userId, TextEditingController.new);
    }
    if (!_participantsInitialized) {
      _selectedParticipantIds.addAll(members.map((member) => member.userId));
      _participantsInitialized = true;
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.scanTakePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.scanChooseGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 72,
    );
    if (image != null && mounted) {
      setState(() => _imageFilePath = image.path);
      await _runOcr(image.path);
    }
  }

  Future<void> _showSplitModeGuide(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.64,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, controller) => Material(
          color: context.moniaryColors.backgroundSoft,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.moniaryColors.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  children: [
                    Text(
                      context.l10n.groupSplitGuideTitle,
                      style: context.moniaryTypography.displaySmall.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(context.l10n.groupSplitGuideIntro),
                    const SizedBox(height: 18),
                    _SplitGuideItem(
                      icon: Icons.balance_outlined,
                      title: context.l10n.groupSplitGuideEqualTitle,
                      body: context.l10n.groupSplitGuideEqualBody,
                    ),
                    _SplitGuideItem(
                      icon: Icons.edit_note_outlined,
                      title: context.l10n.groupSplitGuideExactTitle,
                      body: context.l10n.groupSplitGuideExactBody,
                    ),
                    _SplitGuideItem(
                      icon: Icons.tune_outlined,
                      title: context.l10n.groupSplitGuideUnequalTitle,
                      body: context.l10n.groupSplitGuideUnequalBody,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.groupSplitGuideClose),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runOcr(String imagePath) async {
    setState(() => _ocrLoading = true);
    try {
      final result = await ref
          .read(ocrExtractionControllerProvider)
          .extractFromImage(imagePath);
      if (!mounted) return;
      setState(() {
        final total = result.totalSuggestion;
        final merchant = result.merchantSuggestion;
        if (total != null && !total.needsReview) {
          _amountController.text = total.value.toString();
        }
        if (merchant != null && !merchant.needsReview) {
          _captionController.text = merchant.value;
        }
        _ocrItems = result.items;
        _ocrCategoryKey = result.categorySuggestion?.needsReview == false
            ? result.categoryKey
            : null;
        _hasOcrSuggestions =
            total != null || merchant != null || result.items.isNotEmpty;
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to apply OCR to group transaction',
        error,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.scanReadError)));
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  void _resolveOcrCategory(List<Category> categories) {
    if (_categoryId != null || _ocrCategoryKey == null) return;
    final expectedIcon = switch (_ocrCategoryKey) {
      'food' => 'restaurant',
      'transport' => 'directions_car',
      'shopping' => 'shopping_bag',
      _ => null,
    };
    if (expectedIcon == null) return;
    for (final category in categories) {
      if (category.icon == expectedIcon) {
        _categoryId = category.id;
        _categoryName = category.name;
        return;
      }
    }
  }

  Future<void> _confirmAndSave(List<SpendingGroupMember> activeMembers) async {
    final totalAmount = _parseMoney(_amountController.text);
    if (totalAmount <= 0) {
      _showMessage(context.l10n.groupAmountRequired);
      return;
    }
    final payerAmounts = _payerAmounts(totalAmount);
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    if (rate <= 0 || !rate.isFinite) {
      _showMessage(context.l10n.groupTransactionExchangeRateInvalid);
      return;
    }
    final baseTotalAmount = (totalAmount * rate).round();
    final basePayerAmounts = _convertAmounts(
      payerAmounts,
      sourceTotal: totalAmount,
      targetTotal: baseTotalAmount,
    );
    final rawShares = _splitMode == GroupSplitMode.exact
        ? _shareAmounts()
        : const <String, int>{};
    final baseShareAmounts = _convertAmounts(
      rawShares,
      sourceTotal: totalAmount,
      targetTotal: baseTotalAmount,
    );
    try {
      const GroupSplitCalculator().validateDraft(
        totalAmount: totalAmount,
        activeMemberIds: activeMembers.map((member) => member.userId).toList(),
        participantIds: _selectedParticipantIds.toList(growable: false),
        splitMode: _splitMode,
        paymentMode: _paymentMode,
        shareAmounts: _shareAmounts(),
        payerAmounts: payerAmounts,
      );
    } on GroupSplitException catch (error) {
      _showMessage(_splitErrorMessage(error.error));
      return;
    }

    if (_editing && widget.args.initialDetail!.transaction.hasSettlementLock) {
      _showMessage(context.l10n.groupTransactionSettlementLocked);
      return;
    }
    if (!mounted) return;
    final confirmed = await _showConfirmation(
      context.l10n.groupConfirmationTitle,
    );
    if (!confirmed || !mounted) return;

    final draft = GroupTransactionDraft(
      groupId: widget.args.groupId,
      totalAmount: baseTotalAmount,
      currencyCode: _currencyCode,
      exchangeRateToBase: rate,
      categoryId: _categoryId,
      categoryName: _categoryName,
      caption: _captionController.text,
      note: _noteController.text,
      imageFilePath: _imageFilePath,
      splitMode: _splitMode,
      paymentMode: _paymentMode,
      payerAmounts: basePayerAmounts,
      participantIds: _selectedParticipantIds.toList(growable: false),
      shareAmounts: baseShareAmounts,
    );
    try {
      if (_editing) {
        await ref
            .read(groupActionControllerProvider.notifier)
            .updateTransaction(
              transactionId: widget.args.initialDetail!.transaction.id,
              draft: draft,
            );
      } else {
        await ref
            .read(groupActionControllerProvider.notifier)
            .createTransaction(draft);
      }
      if (!mounted) return;
      _showMessage(
        _splitMode == GroupSplitMode.unequal
            ? context.l10n.groupTransactionPendingAmounts
            : context.l10n.groupTransactionPosted,
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(userFriendlyMessage(context, error));
    }
  }

  Map<String, int> _payerAmounts(int totalAmount) {
    if (_paymentMode == GroupPaymentMode.everyonePaid) {
      return const {};
    }
    if (_paymentMode == GroupPaymentMode.singlePayer) {
      if (_selectedPayerIds.length != 1) return const {};
      return {_selectedPayerIds.first: totalAmount};
    }
    return {
      for (final id in _selectedPayerIds)
        id: _parseMoney(_payerControllers[id]?.text ?? ''),
    };
  }

  Map<String, int> _shareAmounts() => {
    for (final id in _selectedParticipantIds)
      id: _parseMoney(_shareControllers[id]?.text ?? ''),
  };

  Map<String, int> _convertAmounts(
    Map<String, int> values, {
    required int sourceTotal,
    required int targetTotal,
  }) {
    if (values.isEmpty || sourceTotal <= 0) return values;
    final converted = <String, int>{
      for (final entry in values.entries)
        entry.key: (entry.value * targetTotal / sourceTotal).round(),
    };
    final difference =
        targetTotal -
        converted.values.fold<int>(0, (sum, value) => sum + value);
    if (difference != 0) {
      final key = converted.keys.last;
      converted[key] = converted[key]! + difference;
    }
    return converted;
  }

  int _parseMoney(String input) =>
      int.tryParse(input.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _splitErrorMessage(GroupSplitError error) => switch (error) {
    GroupSplitError.payerRequired => context.l10n.groupSelectPayer,
    GroupSplitError.multiplePayersRequired =>
      context.l10n.groupSelectAtLeastTwoPayers,
    GroupSplitError.payerAmountRequired => context.l10n.groupEnterPayerAmounts,
    GroupSplitError.payerAmountNotPositive =>
      context.l10n.groupPayerAmountPositive,
    GroupSplitError.paidTotalMismatch => context.l10n.groupPaidTotalMismatch,
    GroupSplitError.noActiveMembers => context.l10n.groupNoMembers,
    GroupSplitError.participantNotActive => context.l10n.groupNoMembers,
    GroupSplitError.shareTotalMismatch =>
      context.l10n.groupTransactionAmountMismatch,
    _ => context.l10n.groupActionFailed,
  };

  Future<bool> _showConfirmation(String message) async {
    return showGroupConfirmationDialog(context, message: message);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.localPath,
    required this.storagePath,
    required this.onPick,
  });

  final String? localPath;
  final String? storagePath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.outline),
          ),
          child: localPath != null
              ? Image.file(File(localPath!), fit: BoxFit.cover)
              : storagePath != null
              ? SupabaseImage(
                  imagePath: storagePath,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(32),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined, size: 46),
                    const SizedBox(height: 10),
                    Text(context.l10n.groupChooseImage),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: const TextStyle(color: AppTheme.amber)),
    );
  }
}

class _SplitGuideItem extends StatelessWidget {
  const _SplitGuideItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.moniaryColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
