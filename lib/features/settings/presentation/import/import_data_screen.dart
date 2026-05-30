import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moniary/app/app_theme.dart';
import 'package:moniary/features/settings/application/import_controller.dart';
import 'package:moniary/features/wallets/application/wallets_controller.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/shared/utils/app_logger.dart';

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
      appBar: AppBar(title: const Text('Import Data (CSV)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructions(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select CSV File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mint,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            if (importState.isParsing)
              const Center(child: CircularProgressIndicator())
            else if (importState.error != null)
              Center(
                child: Text(
                  importState.error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              )
            else if (importState.parsedRows.isNotEmpty)
              Expanded(child: _buildPreview(importState)),

            if (importState.parsedRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWalletSelector(walletsAsync),
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm Import'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CSV Format Required:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Row 1 is skipped (headers).\n'
            '1. Date (YYYY-MM-DD)\n'
            '2. Amount\n'
            '3. Type (Income/Expense/Thu/Chi)\n'
            '4. Category Name\n'
            '5. Note',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector(AsyncValue<List<Wallet>> walletsAsync) {
    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty)
          return const Text(
            'No wallets found. Create a wallet first.',
            style: TextStyle(color: Colors.red),
          );
        return DropdownButtonFormField<Wallet>(
          value: _selectedWallet,
          hint: const Text(
            'Select target wallet',
            style: TextStyle(color: Colors.white54),
          ),
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
      error: (e, _) => Text(
        'Error loading wallets: $e',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildPreview(ImportState state) {
    final validCount = state.parsedRows.where((r) => r.isValid).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview ($validCount valid rows)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
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
                leading: Icon(
                  row.isValid ? Icons.check_circle : Icons.error,
                  color: row.isValid ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${row.categoryName} - ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(row.amount ?? 0)}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  row.isValid
                      ? DateFormat('dd/MM/yyyy').format(row.date!)
                      : (row.errorMessage ?? 'Unknown error'),
                  style: TextStyle(
                    color: row.isValid ? Colors.white70 : Colors.redAccent,
                  ),
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
        ref
            .read(importControllerProvider.notifier)
            .pickAndParseFile(result.files.single.path!);
      }
    } catch (e) {
      AppLogger.error('File pick error: $e');
    }
  }

  Future<void> _confirmImport() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    final profileId = session?.user.id ?? 'anonymous';
    final count = await ref
        .read(importControllerProvider.notifier)
        .confirmImport(_selectedWallet!, profileId);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $count transactions')));
      Navigator.pop(context);
    }
  }
}
