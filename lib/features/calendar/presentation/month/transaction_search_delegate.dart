import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../../transactions/domain/models/transaction_entry.dart';

class TransactionSearchDelegate extends SearchDelegate<TransactionEntry?> {
  TransactionSearchDelegate({
    required this.ref,
    required this.searchFieldLabelText,
  });

  final WidgetRef ref;
  final String searchFieldLabelText;

  @override
  String get searchFieldLabel => searchFieldLabelText;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white54),
      ),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white70),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          context.l10n.calendarSearchPrompt,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    return _buildSearchList(context);
  }

  Widget _buildSearchList(BuildContext context) {
    final repo = ref.read(transactionRepositoryProvider);

    return FutureBuilder<List<TransactionEntry>>(
      future: repo.searchTransactions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mint),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              userFriendlyMessage(context, snapshot.error!),
              style: const TextStyle(color: AppTheme.danger),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Text(
              context.l10n.calendarSearchNoResults,
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (tx.isIncome ? AppTheme.success : AppTheme.danger)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.isIncome ? Icons.north_east : Icons.south_east,
                  color: tx.isIncome ? AppTheme.success : AppTheme.danger,
                  size: 16,
                ),
              ),
              title: Text(
                tx.note?.trim().isNotEmpty == true
                    ? tx.note!.trim()
                    : tx.categoryName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(tx.transactionDate)} - ${tx.walletName}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: ObscurableAmountText(
                amountText: '${_formatMoney(tx.amount)}đ',
                style: TextStyle(
                  color: tx.isIncome ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => close(context, tx),
            );
          },
        );
      },
    );
  }

  String _formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }
}
