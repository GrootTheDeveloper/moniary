import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_color.dart';
import '../domain/models/wallet.dart';
import '../application/wallets_controller.dart';

class WalletSection extends ConsumerWidget {
  const WalletSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsControllerProvider);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

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
                      'Ví / Tài khoản',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showWalletForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý ví mặc định, số dư khởi tạo và trạng thái kích hoạt.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              walletsAsync.when(
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return const Text('Chưa có ví nào.');
                  }

                  return Column(
                    children: wallets
                        .map(
                          (wallet) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WalletTile(
                              wallet: wallet,
                              balanceLabel: currency.format(
                                wallet.initialBalance,
                              ),
                              onEdit: () =>
                                  _showWalletForm(context, ref, wallet: wallet),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                error: (error, stackTrace) => Text('Lỗi ví: $error'),
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
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Chip(label: Text('Mặc định')),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${wallet.type.label} • $balanceLabel • ${wallet.isActive ? 'Đang dùng' : 'Đã ẩn'}',
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
              isEditing ? 'Sửa ví' : 'Tạo ví',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên ví'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WalletType>(
              initialValue: _selectedType,
              items: WalletType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
              decoration: const InputDecoration(labelText: 'Loại ví'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Số dư ban đầu'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              onChanged: (value) => setState(() => _isDefault = value),
              title: const Text('Đặt làm ví mặc định'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const Text('Đang kích hoạt'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Đang lưu...' : 'Lưu ví'),
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
        const SnackBar(content: Text('Tên ví không được trống.')),
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

      Navigator.of(context).pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      setState(() => _isSubmitting = false);
    }
  }
}
