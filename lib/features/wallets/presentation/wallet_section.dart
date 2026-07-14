import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_color.dart';
import '../../../shared/utils/currency_formatting_ref.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/obscurable_amount_text.dart';
import '../domain/models/wallet.dart';
import '../application/wallets_controller.dart';

class WalletSection extends ConsumerWidget {
  const WalletSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final colors = context.moniaryColors;

    return walletsAsync.when(
      data: (wallets) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionToolbar(
              countLabel:
                  '${wallets.length} ${context.l10n.manageDataWalletCountLabel}',
              onAdd: () => _showWalletForm(context, ref),
            ),
            const SizedBox(height: 10),
            if (wallets.isEmpty)
              Text(
                context.l10n.walletEmpty,
                style: TextStyle(color: colors.textDim),
              )
            else
              ...wallets.map(
                (wallet) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _WalletTile(
                    wallet: wallet,
                    balanceLabel: ref.formatAmount(wallet.initialBalance),
                    onEdit: () => _showWalletForm(context, ref, wallet: wallet),
                  ),
                ),
              ),
          ],
        );
      },
      error: (error, stackTrace) {
        AppLogger.error('Failed to load wallets section', error, stackTrace);
        return Text(
          context.l10n.walletError(userFriendlyMessage(context, error)),
          style: TextStyle(color: colors.danger),
        );
      },
      loading: () => LinearProgressIndicator(
        minHeight: 2,
        color: colors.primary,
        backgroundColor: colors.outline.withValues(alpha: 0.35),
      ),
    );
  }
}

class _SectionToolbar extends StatelessWidget {
  const _SectionToolbar({required this.countLabel, required this.onAdd});

  final String countLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: colors.textDim,
              fontSize: 9,
              letterSpacing: 1.4,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              '+ ${context.l10n.commonAdd}',
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: colors.primary,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.balanceLabel,
    required this.onEdit,
  });

  final Wallet wallet;
  final String balanceLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final color = AppColor.fromHex(wallet.color, fallback: colors.primary);

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 13, 9, 13),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_walletIconData(wallet.icon), color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                      ),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 8),
                        _DefaultBadge(label: context.l10n.walletDefault),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  DefaultTextStyle.merge(
                    style: context.moniaryTypography.metadata.copyWith(
                      color: colors.textDim,
                      fontSize: 8.5,
                      letterSpacing: 1.1,
                      height: 1.25,
                    ),
                    child: ObscurableAmountText(
                      prefixText:
                          '${_walletTypeLabel(context, wallet.type).toUpperCase()} · ',
                      amountText: balanceLabel,
                      suffixText:
                          ' · ${(wallet.isActive ? context.l10n.walletActive : context.l10n.walletInactive).toUpperCase()}',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: colors.textSecondary,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.walletEditTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: colors.success,
          fontSize: 7,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

Future<void> _showWalletForm(
  BuildContext context,
  WidgetRef ref, {
  Wallet? wallet,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _WalletFormSheet(wallet: wallet),
  );
}

class _WalletFormSheet extends ConsumerStatefulWidget {
  const _WalletFormSheet({this.wallet});

  final Wallet? wallet;

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late WalletType _selectedType;
  late bool _isDefault;
  late bool _isActive;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.wallet?.initialBalance.toString() ?? '0',
    );
    _selectedType = widget.wallet?.type ?? WalletType.cash;
    _isDefault = widget.wallet?.isDefault ?? false;
    _isActive = widget.wallet?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.wallet != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? context.l10n.walletEditTitle
                  : context.l10n.walletCreateTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: context.l10n.walletName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WalletType>(
              initialValue: _selectedType,
              items: WalletType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_walletTypeLabel(context, type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
              decoration: InputDecoration(labelText: context.l10n.walletType),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.walletInitialBalance,
                suffixText: ref.currencySymbol,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              title: Text(context.l10n.walletSetDefault),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: Text(context.l10n.walletActivated),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(
                _isSubmitting
                    ? context.l10n.walletSaving
                    : context.l10n.walletSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0;

    if (name.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.walletNameRequired)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final controller = ref.read(walletsControllerProvider.notifier);
      if (widget.wallet == null) {
        await controller.createWallet(
          name: name,
          type: _selectedType,
          initialBalance: balance,
          isDefault: _isDefault,
        );
      } else {
        await controller.updateWallet(
          walletId: widget.wallet!.id,
          name: name,
          type: _selectedType,
          initialBalance: balance,
          isDefault: _isDefault,
          isActive: _isActive,
        );
      }

      if (!mounted) {
        return;
      }

      context.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}

String _walletTypeLabel(BuildContext context, WalletType type) {
  return switch (type) {
    WalletType.cash => context.l10n.walletTypeCash,
    WalletType.bank => context.l10n.walletTypeBank,
    WalletType.ewallet => context.l10n.walletTypeEwallet,
    WalletType.credit => context.l10n.walletTypeCredit,
    WalletType.other => context.l10n.walletTypeOther,
  };
}

IconData _walletIconData(String? name) {
  return switch (name) {
    'payment' => Icons.payments_outlined,
    'bank' => Icons.account_balance_outlined,
    'card' => Icons.credit_card_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };
}
