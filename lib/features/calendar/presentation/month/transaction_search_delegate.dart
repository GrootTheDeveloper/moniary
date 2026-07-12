import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
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
    final colors = context.moniaryColors;
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: colors.textDim),
      ),
      textTheme: Theme.of(context).textTheme.copyWith(
        titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontFamily: 'Manrope',
          fontSize: 17,
        ),
      ),
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
              color: _showStarredOnly
                  ? context.moniaryColors.warning
                  : context.moniaryColors.textDim,
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
          icon: Icon(Icons.clear, color: context.moniaryColors.textDim),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: context.moniaryColors.textPrimary),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 44,
                color: context.moniaryColors.textDim,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.calendarSearchPrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
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
          return const Center(child: CircularProgressIndicator());
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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_outlined,
                    size: 44,
                    color: context.moniaryColors.textDim,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.calendarSearchNoResults,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final tx = filtered[index];
            final amountColor = tx.isIncome
                ? context.moniaryColors.success
                : context.moniaryColors.danger;
            return MoniaryHairlineTile(
              showTopDivider: index == 0,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              leading: Icon(
                tx.isIncome ? Icons.north_east : Icons.south_east,
                color: amountColor,
                size: 18,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.note?.trim().isNotEmpty == true
                          ? tx.note!.trim()
                          : tx.categoryName,
                    ),
                  ),
                  if (tx.isImportant) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: AppTheme.amber, size: 14),
                  ],
                ],
              ),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatShortDate(tx.transactionDate)} · ${tx.walletName}',
                style: context.moniaryTypography.metadata,
              ),
              trailing: ObscurableAmountText(
                amountText: _formatMoney(context, tx.amount),
                style: TextStyle(
                  color: amountColor,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
