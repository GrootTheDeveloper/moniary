import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../categories/domain/models/category.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/services/group_split_calculator.dart';
import '../widgets/group_confirmation_dialog.dart';
import '../widgets/payer_amount_input_list.dart';
import '../widgets/payment_mode_selector.dart';
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
  final Map<String, TextEditingController> _payerControllers = {};
  final Set<String> _selectedPayerIds = {};
  GroupSplitMode _splitMode = GroupSplitMode.equal;
  GroupPaymentMode _paymentMode = GroupPaymentMode.everyonePaid;
  String? _categoryId;
  String? _categoryName;
  String? _imageFilePath;

  bool get _editing => widget.args.initialDetail != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.args.initialDetail;
    if (initial != null) {
      final transaction = initial.transaction;
      _amountController.text = transaction.totalAmount.toString();
      _captionController.text = transaction.caption ?? '';
      _noteController.text = transaction.note ?? '';
      _splitMode = transaction.splitMode;
      _paymentMode = transaction.paymentMode;
      _categoryId = transaction.categoryId;
      _categoryName = transaction.categoryName;
      for (final payer in initial.payers) {
        _selectedPayerIds.add(payer.userId);
        _payerControllers[payer.userId] = TextEditingController(
          text: payer.paidAmount.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _captionController.dispose();
    _noteController.dispose();
    for (final controller in _payerControllers.values) {
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
          _ensurePayerControllers(detail.activeMembers);
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
              const SizedBox(height: 18),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.groupTransactionTotal,
                  suffixText: activeCurrencySymbol(),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
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
              Text(
                context.l10n.groupSplitModeTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SplitModeSelector(
                value: _splitMode,
                onChanged: (value) => setState(() => _splitMode = value),
              ),
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

  void _ensurePayerControllers(List<SpendingGroupMember> members) {
    for (final member in members) {
      _payerControllers.putIfAbsent(member.userId, TextEditingController.new);
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (image != null && mounted) {
      setState(() => _imageFilePath = image.path);
    }
  }

  Future<void> _confirmAndSave(List<SpendingGroupMember> activeMembers) async {
    final totalAmount = _parseMoney(_amountController.text);
    if (totalAmount <= 0) {
      _showMessage(context.l10n.groupAmountRequired);
      return;
    }
    final payerAmounts = _payerAmounts(totalAmount);
    try {
      const GroupSplitCalculator().calculate(
        totalAmount: totalAmount,
        activeMemberIds: activeMembers.map((member) => member.userId).toList(),
        splitMode: GroupSplitMode.equal,
        paymentMode: _paymentMode,
        payerAmounts: payerAmounts,
      );
    } on GroupSplitException catch (error) {
      _showMessage(_splitErrorMessage(error.error));
      return;
    }

    if (_editing &&
        widget.args.initialDetail!.transaction.hasCompletedSettlement) {
      final continueEditing = await _showConfirmation(
        context.l10n.groupTransactionCompletedEditWarning,
      );
      if (!continueEditing) return;
    }
    if (!mounted) return;
    final confirmed = await _showConfirmation(
      context.l10n.groupConfirmationTitle,
    );
    if (!confirmed || !mounted) return;

    final draft = GroupTransactionDraft(
      groupId: widget.args.groupId,
      totalAmount: totalAmount,
      categoryId: _categoryId,
      categoryName: _categoryName,
      caption: _captionController.text,
      note: _noteController.text,
      imageFilePath: _imageFilePath,
      splitMode: _splitMode,
      paymentMode: _paymentMode,
      payerAmounts: payerAmounts,
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
