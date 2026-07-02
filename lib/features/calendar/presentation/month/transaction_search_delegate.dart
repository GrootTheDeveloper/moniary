import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../transactions/application/queries/transaction_queries.dart';
import '../../../transactions/domain/models/transaction_entry.dart';

class TransactionSearchDelegate extends SearchDelegate<TransactionEntry?> {
  TransactionSearchDelegate({
    required this.ref,
    required this.searchFieldLabelText,
  });

  final WidgetRef ref;
  final String searchFieldLabelText;

  bool _showStarredOnly = false;

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
      StatefulBuilder(
        builder: (context, setState) {
          return IconButton(
            icon: Icon(
              _showStarredOnly ? Icons.star : Icons.star_border,
              color: _showStarredOnly ? AppTheme.amber : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showStarredOnly = !_showStarredOnly;
              });
              showSuggestions(context);
            },
            tooltip: context.l10n.calendarStarred,
          );
        },
      ),
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
    return FutureBuilder<List<TransactionEntry>>(
      future: ref.read(transactionSearchProvider(query).future),
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
        var filtered = transactions;

        if (_showStarredOnly) {
          filtered = filtered.where((tx) => tx.isImportant).toList();
        }

        // Sort: Starred items first, then by date (already sorted by date from repo)
        filtered.sort((a, b) {
          if (a.isImportant != b.isImportant) {
            return b.isImportant ? 1 : -1;
          }
          return b.transactionDate.compareTo(a.transactionDate);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              context.l10n.calendarSearchNoResults,
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final tx = filtered[index];
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
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.note?.trim().isNotEmpty == true
                          ? tx.note!.trim()
                          : tx.categoryName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (tx.isImportant) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: AppTheme.amber, size: 14),
                  ],
                ],
              ),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatShortDate(tx.transactionDate)} - ${tx.walletName}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: ObscurableAmountText(
                amountText: _formatMoney(context, tx.amount),
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

  String _formatMoney(BuildContext context, double amount) {
    final formatter = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: '',
      decimalDigits: 0,
    );
    return '${formatter.format(amount).trim()}${context.l10n.transactionAmountSuffix}';
  }
}
