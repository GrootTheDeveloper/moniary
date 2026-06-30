import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_color.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../shared/utils/currency_formatter.dart';
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
    final currencyCode = ref.watch(preferredCurrencyProvider);
    final localeName = Localizations.localeOf(context).toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.walletTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showWalletForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.commonAdd),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.walletDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              walletsAsync.when(
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return Text(context.l10n.walletEmpty);
                  }

                  return Column(
                    children: wallets
                        .map(
                          (wallet) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WalletTile(
                              wallet: wallet,
                              balanceLabel: formatCurrency(
                                wallet.initialBalance,
                                currencyCode: currencyCode,
                                locale: localeName,
                              ),
                              onEdit: () =>
                                  _showWalletForm(context, ref, wallet: wallet),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                error: (error, stackTrace) {
                  AppLogger.error(
                    'Failed to load wallets section',
                    error,
                    stackTrace,
                  );
                  return Text(
                    context.l10n.walletError(
                      userFriendlyMessage(context, error),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final color = AppColor.fromHex(
      wallet.color,
      fallback: const Color(0xFF4EA1FF),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          child: const Icon(Icons.account_balance_wallet_outlined),
        ),
        title: Row(
          children: [
            Expanded(child: Text(wallet.name)),
            if (wallet.isDefault)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(label: Text(context.l10n.walletDefault)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ObscurableAmountText(
            prefixText: '${_walletTypeLabel(context, wallet.type)} • ',
            amountText: balanceLabel,
            suffixText:
                ' • ${wallet.isActive ? context.l10n.walletActive : context.l10n.walletInactive}',
          ),
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
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
                suffixText: currencySymbolFor(
                  currencyCode: ref.watch(preferredCurrencyProvider),
                  locale: Localizations.localeOf(context).toString(),
                ),
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
