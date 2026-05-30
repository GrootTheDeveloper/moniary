import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/settings/application/import_controller.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/l10n/l10n_extension.dart';
import 'package:moniary/shared/utils/app_logger.dart';
import 'package:moniary/shared/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(context.l10n.importTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructions(context),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: Text(context.l10n.importSelectFile),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mint, foregroundColor: Colors.black),
            ),
            const SizedBox(height: 16),
            if (importState.isParsing)
              const Center(child: CircularProgressIndicator())
            else if (importState.error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _getErrorMessage(context, importState.error!),
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _pickFile, child: Text(context.l10n.importRetry)),
                  ],
                ),
              )
            else if (importState.parsedRows.isNotEmpty)
              Expanded(child: _buildPreview(context, importState)),

            if (importState.parsedRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWalletSelector(context, walletsAsync),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _selectedWallet == null || importState.isImporting
                    ? null
                    : _confirmImport,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.mint,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.grey[500],
                ),
                child: importState.isImporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text(context.l10n.importConfirm),
              ),
            ],
          ],
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
          Text(context.l10n.importCsvFormatTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            context.l10n.importCsvFormatBody,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector(BuildContext context, AsyncValue<List<Wallet>> walletsAsync) {
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) return Text(context.l10n.importNoWallets, style: const TextStyle(color: Colors.red));
        return DropdownButtonFormField<Wallet>(
          value: _selectedWallet,
          hint: Text(context.l10n.importSelectWallet, style: const TextStyle(color: Colors.white54)),
          dropdownColor: AppTheme.surface,
          items: wallets
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text(
                    w.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedWallet = val),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.importErrorWallets(e.toString()), style: const TextStyle(color: Colors.red)),
    );
  }

  String _getErrorMessage(BuildContext context, String code) {
    switch (code) {
      case 'MISSING_COLUMNS': return context.l10n.importErrorMissingColumns;
      case 'INVALID_DATE': return context.l10n.importErrorInvalidDate;
      case 'INVALID_AMOUNT': return context.l10n.importErrorInvalidAmount;
      default: return context.l10n.importErrorUnknown;
    }
  }

  Widget _buildPreview(BuildContext context, ImportState state) {
    final validCount = state.parsedRows.where((r) => r.isValid).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.importPreviewTitle(validCount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: state.parsedRows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = state.parsedRows[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppTheme.surface,
                leading: Icon(row.isValid ? Icons.check_circle : Icons.error, color: row.isValid ? Colors.green : Colors.red),
                title: Text('${row.categoryName} - ${formatVnd(row.amount ?? 0)}', style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  row.isValid
                      ? DateFormat('dd/MM/yyyy').format(row.date!)
                      : _getErrorMessage(context, row.errorMessage ?? ''),
                  style: TextStyle(color: row.isValid ? Colors.white70 : Colors.redAccent),
                ),
              );
            },
          ),
        ),
      ],
    );
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
    } catch (e) {
      AppLogger.error('File pick error: $e');
    }
  }

  Future<void> _confirmImport() async {
    final count = await ref.read(importControllerProvider.notifier).confirmImport(_selectedWallet!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.importSuccess(count))));
      context.pop();
    }
  }
}
