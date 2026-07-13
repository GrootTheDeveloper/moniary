import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../transactions/application/queries/transaction_queries.dart';
import '../../../transactions/domain/models/transaction_entry.dart';
import '../../../transactions/presentation/utils/transaction_image_source.dart';

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
    final baseTheme = Theme.of(context);
    final searchFill = Color.lerp(colors.backgroundSoft, colors.surface, 0.42)!;
    return baseTheme.copyWith(
      scaffoldBackgroundColor: colors.backgroundSoft,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.backgroundSoft,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        toolbarHeight: 65,
        centerTitle: false,
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _searchBorder(colors)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _searchBorder(colors)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _searchBorder(colors), width: 1.2),
        ),
        hintStyle: TextStyle(color: colors.textDim, fontSize: 13),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontFamily: 'Manrope',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: context.moniaryColors.textDim,
            size: 18,
          ),
          onPressed: () => query = '',
        ),
      TextButton(
        onPressed: () => close(context, null),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.terracotta,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Text(context.l10n.commonCancel),
      ),
      const SizedBox(width: 10),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 13),
      child: Icon(
        Icons.search_rounded,
        size: 18,
        color: context.moniaryColors.icon,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _SearchShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(label: context.l10n.calendarRecentSearches),
            const SizedBox(height: 14),
            _RecentSearchChips(
              showStarredOnly: _showStarredOnly,
              onRecentSelected: (value) {
                query = value;
                showResults(context);
              },
              onStarredChanged: (value) {
                _showStarredOnly = value;
                showSuggestions(context);
              },
            ),
            const SizedBox(height: 34),
            Text(
              context.l10n.calendarSearchPrompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.moniaryColors.textDim,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
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
          return _SearchShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                  label: context.l10n.calendarSearchResultsHeader(query, 0),
                ),
                const SizedBox(height: 18),
                ...List.generate(4, (index) => const _SearchSkeletonRow()),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _SearchShell(
            child: _SearchMessage(
              icon: Icons.error_outline_rounded,
              message: userFriendlyMessage(context, snapshot.error!),
              color: AppTheme.danger,
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
          return _SearchShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(
                  label: context.l10n.calendarSearchResultsHeader(query, 0),
                ),
                const SizedBox(height: 58),
                _SearchMessage(
                  icon: Icons.search_off_rounded,
                  message: context.l10n.calendarSearchNoResults,
                  color: context.moniaryColors.textDim,
                ),
              ],
            ),
          );
        }

        return _SearchShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                label: context.l10n.calendarSearchResultsHeader(
                  query,
                  filtered.length,
                ),
              ),
              const SizedBox(height: 14),
              _RecentSearchChips(
                compact: true,
                showStarredOnly: _showStarredOnly,
                onRecentSelected: (value) {
                  query = value;
                  showResults(context);
                },
                onStarredChanged: (value) {
                  _showStarredOnly = value;
                  showResults(context);
                },
              ),
              const SizedBox(height: 14),
              ...List.generate(filtered.length, (index) {
                final tx = filtered[index];
                return _SearchResultRow(
                  transaction: tx,
                  showTopDivider: index == 0,
                  onTap: () => close(context, tx),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );
}

class _SearchShell extends StatelessWidget {
  const _SearchShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.moniaryColors.backgroundSoft,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 393),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(23, 13, 23, 42),
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.moniaryTypography.metadataStrong.copyWith(
        color: context.moniaryColors.textDim,
        fontSize: 9,
        letterSpacing: 2.1,
      ),
    );
  }
}

class _RecentSearchChips extends StatelessWidget {
  const _RecentSearchChips({
    required this.showStarredOnly,
    required this.onRecentSelected,
    required this.onStarredChanged,
    this.compact = false,
  });

  final bool showStarredOnly;
  final ValueChanged<String> onRecentSelected;
  final ValueChanged<bool> onStarredChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chips = [
      context.l10n.calendarRecentSearchCoffee,
      context.l10n.calendarRecentSearchRide,
      context.l10n.calendarRecentSearchMarket,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...chips.map(
          (label) => _SearchChip(
            label: label,
            compact: compact,
            selected: false,
            onTap: () => onRecentSelected(label),
          ),
        ),
        _SearchChip(
          label: context.l10n.calendarStarred,
          icon: showStarredOnly
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          compact: compact,
          selected: showStarredOnly,
          onTap: () => onStarredChanged(!showStarredOnly),
        ),
      ],
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: selected ? colors.textPrimary : _controlFill(colors),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.textPrimary : _searchBorder(colors),
          width: 1.15,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? colors.surfaceRaised : colors.textDim,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.surfaceRaised : colors.textSecondary,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.transaction,
    required this.showTopDivider,
    required this.onTap,
  });

  final TransactionEntry transaction;
  final bool showTopDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : transaction.categoryName;
    final amountColor = transaction.isIncome
        ? colors.success
        : colors.textPrimary;

    return Column(
      children: [
        if (showTopDivider)
          Divider(height: 1, color: colors.outline.withValues(alpha: 0.74)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  _TransactionPhotoThumb(transaction: transaction),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontSize: 14.3,
                                      fontWeight: FontWeight.w800,
                                      height: 1.16,
                                    ),
                              ),
                            ),
                            if (transaction.isImportant) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.sand,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${_formatSearchDate(context, transaction.transactionDate)} · '
                          '${DateFormat('HH:mm').format(transaction.transactionDate)} · '
                          '${transaction.walletName.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                            fontSize: 8.6,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ObscurableAmountText(
                    amountText:
                        '${transaction.isIncome ? '+' : '-'}${formatVnd(transaction.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: colors.outline.withValues(alpha: 0.74)),
      ],
    );
  }
}

class _TransactionPhotoThumb extends StatelessWidget {
  const _TransactionPhotoThumb({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final accent = AppColor.fromHex(
      transaction.categoryColor ?? transaction.walletColor,
      fallback: transaction.isIncome ? colors.success : AppTheme.taupe,
    );
    final imagePath = transactionImagePathForDisplay(transaction);
    final fallbackAssetPath = transactionFallbackAssetPath(transaction);

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color.lerp(accent, colors.backgroundSoft, 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _searchBorder(colors), width: 1),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SupabaseImage(
                imagePath: imagePath,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                fallbackIcon: Icons.receipt_long_outlined,
                fallbackBuilder: (context) => Image.asset(
                  fallbackAssetPath,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 17,
                      color: _readableTextColor(accent).withValues(alpha: 0.84),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (transaction.isImportant)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.backgroundSoft, width: 1.4),
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: colors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSkeletonRow extends StatelessWidget {
  const _SearchSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          _SkeletonBox(width: 42, height: 42, radius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 126, height: 12, radius: 5),
                const SizedBox(height: 9),
                _SkeletonBox(width: 178, height: 8, radius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SkeletonBox(width: 62, height: 10, radius: 4),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(colors.outline, colors.backgroundSoft, 0.52),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: color.withValues(alpha: 0.86)),
            const SizedBox(height: 13),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.moniaryColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSearchDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'vi') {
    return '${date.day} TH${date.month}';
  }
  return DateFormat(
    'd MMM',
    Localizations.localeOf(context).toString(),
  ).format(date).toUpperCase();
}

Color _controlFill(MoniaryColors colors) {
  return Color.lerp(colors.backgroundSoft, colors.textPrimary, 0.025)!;
}

Color _searchBorder(MoniaryColors colors) {
  return Color.lerp(colors.outline, colors.textPrimary, 0.08)!;
}

Color _readableTextColor(Color color) {
  return color.computeLuminance() > 0.42
      ? AppTheme.ink
      : AppTheme.surfaceRaised;
}
