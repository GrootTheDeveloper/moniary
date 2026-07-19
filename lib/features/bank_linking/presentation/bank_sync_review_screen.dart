import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../categories/application/categories_controller.dart';
import '../../categories/domain/models/category.dart';
import '../../wallets/application/wallets_controller.dart';
import '../../wallets/domain/models/wallet.dart';
import '../application/bank_sync_review_controller.dart';
import '../domain/models/pending_synced_transaction.dart';

class BankSyncReviewScreen extends ConsumerWidget {
  const BankSyncReviewScreen({super.key});

  static const routePath = '/bank-linking/review';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final pendingAsync = ref.watch(bankSyncReviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bankSyncReviewTitle)),
      body: ColoredBox(
        color: colors.background,
        child: pendingAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.bankSyncReviewEmpty,
                  style: TextStyle(color: colors.textDim),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) => _PendingTile(item: items[index]),
            );
          },
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                userFriendlyMessage(context, error),
                style: TextStyle(color: colors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
        ),
      ),
    );
  }
}

class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.item});

  final PendingSyncedTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final locale = Localizations.localeOf(context).toString();
    final isExpense = item.type == TransactionType.expense;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.merchantName ?? item.rawDescription ?? '',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'}${ref.formatAmount(item.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isExpense ? colors.danger : colors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM/yyyy HH:mm', locale).format(item.transactionDate),
            style: TextStyle(color: colors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(bankSyncReviewControllerProvider.notifier)
                      .dismiss(item.id),
                  child: Text(context.l10n.bankSyncReviewDismiss),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _showConfirmSheet(context, ref, item),
                  child: Text(context.l10n.bankSyncReviewConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmSheet(
    BuildContext context,
    WidgetRef ref,
    PendingSyncedTransaction item,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _ConfirmSheet(item: item),
    );
  }
}

class _ConfirmSheet extends ConsumerStatefulWidget {
  const _ConfirmSheet({required this.item});

  final PendingSyncedTransaction item;

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  String? _walletId;
  String? _categoryId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bankSyncReviewConfirm,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            walletsAsync.when(
              data: (wallets) => DropdownButtonFormField<String>(
                initialValue: _walletId,
                isExpanded: true,
                items: wallets
                    .map(
                      (Wallet wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(
                          wallet.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _walletId = value),
                decoration: InputDecoration(
                  labelText: context.l10n.bankSyncReviewSelectWallet,
                ),
              ),
              error: (error, stackTrace) => Text(
                userFriendlyMessage(context, error),
                style: TextStyle(color: context.moniaryColors.danger),
              ),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: (categories) {
                final filtered = categories
                    .where((category) => category.type == widget.item.type)
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  items: filtered
                      .map(
                        (Category category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                  decoration: InputDecoration(
                    labelText: context.l10n.bankSyncReviewSelectCategory,
                  ),
                );
              },
              error: (error, stackTrace) => Text(
                userFriendlyMessage(context, error),
                style: TextStyle(color: context.moniaryColors.danger),
              ),
              loading: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.bankSyncReviewConfirmButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final walletId = _walletId;
    final categoryId = _categoryId;
    if (walletId == null || categoryId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.bankSyncReviewMissingSelection)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(bankSyncReviewControllerProvider.notifier)
          .confirm(
            pendingId: widget.item.id,
            walletId: walletId,
            categoryId: categoryId,
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.bankSyncReviewConfirmSuccess)),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}
