import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/core/constants/app_color.dart';
import 'package:moniary/features/settings/application/import_controller.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/l10n/l10n_extension.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';

import '../../domain/import/import_history_entry.dart';
import '../widgets/recent_history_error_card.dart';
import 'import_history_screen.dart';

class ImportDataScreen extends ConsumerStatefulWidget {
  const ImportDataScreen({super.key});

  static const routePath = '/import';

  @override
  ConsumerState<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends ConsumerState<ImportDataScreen> {
  Wallet? _selectedWallet;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importControllerProvider);
    final walletsAsync = ref.watch(walletsControllerProvider);
    final hasPreview = importState.parsedRows.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(context.l10n.profileImportData)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructions(context),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_download_outlined),
                label: Text(context.l10n.importSelectFile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mint,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (importState.isParsing)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.mint),
                  ),
                )
              else if (importState.error != null)
                Expanded(child: _buildErrorCard(context, importState.error!))
              else if (hasPreview)
                Expanded(child: _buildPreview(context, importState))
              else
                Expanded(child: _RecentImportsSection()),
              if (hasPreview) ...[
                const SizedBox(height: 16),
                _buildWalletSelector(context, ref, walletsAsync),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _selectedWallet == null || importState.isImporting
                      ? null
                      : _confirmImport,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.mint,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.surfaceRaised,
                    disabledForegroundColor: AppTheme.textDim,
                  ),
                  child: importState.isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.l10n.importConfirm),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.importCsvFormatTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.importCsvFormatBody,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String errorCode) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(context, errorCode),
              style: const TextStyle(color: AppTheme.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickFile,
              child: Text(context.l10n.importRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ImportState state) {
    final validCount = state.parsedRows.where((row) => row.isValid).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.importPreviewTitle(validCount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ColoredBox(
              color: AppTheme.background,
              child: ListView.separated(
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.zero,
                itemCount: state.parsedRows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = state.parsedRows[index];
                  return _PreviewRowTile(
                    title:
                        '${row.categoryName} - ${formatCurrency(row.amount ?? 0, currencyCode: ref.watch(preferredCurrencyProvider), locale: Localizations.localeOf(context).toString())}',
                    subtitle: row.isValid
                        ? DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toString()).format(row.date!)
                        : _getErrorMessage(context, row.errorMessage ?? ''),
                    isValid: row.isValid,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSelector(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Wallet>> walletsAsync,
  ) {
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return Text(
            context.l10n.importNoWallets,
            style: const TextStyle(color: AppTheme.danger),
          );
        }

        final selectedStillExists =
            _selectedWallet == null ||
            wallets.any((wallet) => wallet.id == _selectedWallet!.id);
        if (!selectedStillExists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedWallet = null);
          });
        }

        return _WalletPickerCard(
          selectedWallet: selectedStillExists ? _selectedWallet : null,
          onTap: () => _showWalletPicker(wallets),
        );
      },
      loading: () => Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.mint,
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => _WalletLoadErrorCard(
        message: context.l10n.importErrorWallets(context.l10n.errorGeneric),
        onRetry: () => ref.invalidate(walletsControllerProvider),
      ),
    );
  }

  Future<void> _showWalletPicker(List<Wallet> wallets) async {
    final selected = await showModalBottomSheet<Wallet>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalletPickerSheet(
        wallets: wallets,
        selectedWalletId: _selectedWallet?.id,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedWallet = selected);
    }
  }

  String _getErrorMessage(BuildContext context, String code) {
    return switch (code) {
      'MISSING_COLUMNS' => context.l10n.importErrorMissingColumns,
      'INVALID_DATE' => context.l10n.importErrorInvalidDate,
      'INVALID_AMOUNT' => context.l10n.importErrorInvalidAmount,
      'INVALID_TYPE' => context.l10n.importErrorInvalidType,
      'CATEGORY_NOT_FOUND' => context.l10n.importErrorCategoryNotFound,
      'AUTH_REQUIRED' => context.l10n.errorNotLoggedIn,
      'IMPORT_HISTORY_READ_ERROR' ||
      'FILE_IO_ERROR' ||
      'IMPORT_HISTORY_FAIL_ERROR' ||
      'IMPORT_FAILED_HISTORY_FAILED' ||
      'IMPORT_FAILED' ||
      'IMPORT_HISTORY_CREATE_ERROR' ||
      'IMPORT_HISTORY_COMPLETE_ERROR' ||
      'IMPORT_PARSE_ERROR' => context.l10n.errorGeneric,
      _ => context.l10n.importErrorUnknown,
    };
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        await ref
            .read(importControllerProvider.notifier)
            .pickAndParseFile(result.files.single.path!);
      }
    } catch (e, st) {
      AppLogger.error('File pick error', e, st);
    }
  }

  Future<void> _confirmImport() async {
    final count = await ref
        .read(importControllerProvider.notifier)
        .confirmImport(_selectedWallet!);

    if (!mounted || count == null) {
      return;
    }

    final latestState = ref.read(importControllerProvider);
    if (latestState.error != null) {
      final isHistoryError = [
        'IMPORT_HISTORY_COMPLETE_ERROR',
        'IMPORT_HISTORY_READ_ERROR',
        'FILE_IO_ERROR',
        'IMPORT_HISTORY_FAIL_ERROR',
      ].contains(latestState.error);

      if (isHistoryError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.importSuccessWithHistoryError(count)),
            backgroundColor: AppTheme.amber,
          ),
        );
      }
      return;
    }

    setState(() => _selectedWallet = null);
    await _showImportSuccessDialog(count);
  }

  Future<void> _showImportSuccessDialog(int count) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppTheme.success,
          size: 42,
        ),
        title: Text(context.l10n.importStatusCompleted),
        content: Text(
          context.l10n.importSuccess(count),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonClose),
          ),
        ],
      ),
    );
  }
}

class _WalletPickerCard extends StatelessWidget {
  const _WalletPickerCard({required this.selectedWallet, required this.onTap});

  final Wallet? selectedWallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wallet = selectedWallet;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            if (wallet != null) ...[
              _WalletVisual(wallet: wallet),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.transactionWallet,
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet?.name ?? context.l10n.importSelectWallet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: wallet == null
                          ? AppTheme.textSubtle
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSubtle),
          ],
        ),
      ),
    );
  }
}

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({
    required this.wallets,
    required this.selectedWalletId,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          context.l10n.importSelectWallet,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: wallets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final wallet = wallets[index];
                        final selected = wallet.id == selectedWalletId;
                        return _WalletOptionTile(
                          wallet: wallet,
                          selected: selected,
                          onTap: () => Navigator.pop(context, wallet),
                        );
                      },
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
}

class _WalletOptionTile extends StatelessWidget {
  const _WalletOptionTile({
    required this.wallet,
    required this.selected,
    required this.onTap,
  });

  final Wallet wallet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.mint.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.mint : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            _WalletVisual(wallet: wallet),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _walletTypeLabel(context, wallet.type),
                    style: const TextStyle(
                      color: AppTheme.textSubtle,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.mint)
            else
              const Icon(Icons.chevron_right, color: AppTheme.textDim),
          ],
        ),
      ),
    );
  }
}

class _WalletVisual extends StatelessWidget {
  const _WalletVisual({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final color = AppColor.fromHex(
      wallet.color,
      fallback: const Color(0xFF2563EB),
    );

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(_walletIconData(wallet.icon), color: color, size: 22),
    );
  }
}

class _PreviewRowTile extends StatelessWidget {
  const _PreviewRowTile({
    required this.title,
    required this.subtitle,
    required this.isValid,
  });

  final String title;
  final String subtitle;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isValid ? Icons.check_circle_outline : Icons.error_outline,
          color: isValid ? AppTheme.success : AppTheme.danger,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isValid ? AppTheme.textMuted : AppTheme.danger,
          ),
        ),
      ),
    );
  }
}

class _WalletLoadErrorCard extends StatelessWidget {
  const _WalletLoadErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}

class _RecentImportsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(importHistoryProvider);

    return historyAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.importRecentTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(ImportHistoryScreen.routePath),
                    child: Text(context.l10n.commonViewAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...items.take(3).map((item) => _RecentImportTile(entry: item)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) {
        AppLogger.error('Failed to load recent import history', e, st);
        return RecentHistoryErrorCard(
          message: context.l10n.importRecentHistoryError,
          onRetry: () => ref.invalidate(importHistoryProvider),
        );
      },
    );
  }
}

class _RecentImportTile extends StatelessWidget {
  const _RecentImportTile({required this.entry});

  final ImportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.download_done, color: AppTheme.mint),
      title: Text(
        entry.fileName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toString()).format(entry.createdAt)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSubtle),
      onTap: () {
        context.push(ImportHistoryScreen.detailRoutePath, extra: entry);
      },
    );
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
    'wallet' => Icons.account_balance_wallet_outlined,
    'bank' => Icons.account_balance_outlined,
    'credit_card' => Icons.credit_card_outlined,
    _ => Icons.account_balance_wallet_outlined,
  };
}
