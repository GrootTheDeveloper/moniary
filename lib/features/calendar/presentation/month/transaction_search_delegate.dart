import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/obscurable_amount_text.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../../categories/application/categories_controller.dart';
import '../../../categories/domain/models/category.dart';
import '../../../transactions/application/queries/transaction_queries.dart';
import '../../../transactions/application/recent_searches_provider.dart';
import '../../../transactions/domain/models/transaction_entry.dart';
import '../../../transactions/domain/models/transaction_search_filter.dart';
import '../../../transactions/presentation/utils/transaction_image_source.dart';

class TransactionSearchDelegate extends SearchDelegate<TransactionEntry?> {
  TransactionSearchDelegate({
    required this.ref,
    required this.searchFieldLabelText,
  });

  final WidgetRef ref;
  final String searchFieldLabelText;

  // Drives body rebuilds on filter changes. SearchDelegate's showResults only
  // rebuilds when the phase actually changes, so it silently ignores repeat
  // calls — bumping this notifier forces the body to re-read the filter.
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  TransactionType? _type;
  TransactionImportanceFilter? _importance;
  TransactionSubscriptionFilter? _subscription;
  String? _categoryId;
  String? _categoryName;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double? _minAmount;
  double? _maxAmount;

  TransactionSearchFilter get _filter => TransactionSearchFilter(
    query: query,
    type: _type,
    importance: _importance,
    subscription: _subscription,
    categoryId: _categoryId,
    dateFrom: _dateFrom,
    dateTo: _dateTo,
    minAmount: _minAmount,
    maxAmount: _maxAmount,
  );

  void _bump() => _revision.value++;

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
    _recordRecentSearch();
    return _buildBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _revision,
      builder: (context, _, _) => _buildBodyContent(context),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    final filter = _filter;
    return ColoredBox(
      color: context.moniaryColors.backgroundSoft,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _buildFilterHeader(context),
                Expanded(child: _buildResultsArea(context, filter)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterScrollRow(
            children: [
              _FilterEntryChip(
                icon: Icons.category_outlined,
                label: _categoryName ?? context.l10n.searchFilterCategory,
                active: _categoryName != null,
                onTap: () => _pickCategory(context),
              ),
              _FilterEntryChip(
                icon: Icons.date_range_outlined,
                label: _dateLabel() ?? context.l10n.searchFilterDate,
                active: _dateLabel() != null,
                onTap: () => _pickDateRange(context),
              ),
              _FilterEntryChip(
                icon: Icons.payments_outlined,
                label: _amountLabel() ?? context.l10n.searchFilterAmount,
                active: _amountLabel() != null,
                onTap: () => _pickAmountRange(context),
              ),
              if (_filter.hasActiveFilters)
                _FilterEntryChip(
                  icon: Icons.filter_alt_off_outlined,
                  label: context.l10n.searchFilterClearAll,
                  active: false,
                  showChevron: false,
                  onTap: () => _clearFilters(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _SegmentedFilter<TransactionType?>(
            label: context.l10n.searchFilterType,
            value: _type,
            options: [
              _SegOption(context.l10n.searchFilterAll, null),
              _SegOption(context.l10n.searchFilterIncome, TransactionType.income),
              _SegOption(
                context.l10n.searchFilterExpense,
                TransactionType.expense,
              ),
            ],
            onChanged: (value) {
              _type = value;
              _bump();
            },
          ),
          const SizedBox(height: 10),
          _SegmentedFilter<TransactionImportanceFilter?>(
            label: context.l10n.searchFilterImportance,
            value: _importance,
            options: [
              _SegOption(context.l10n.searchFilterAll, null),
              _SegOption(
                context.l10n.searchImportanceImportant,
                TransactionImportanceFilter.important,
              ),
              _SegOption(
                context.l10n.searchImportanceNotImportant,
                TransactionImportanceFilter.notImportant,
              ),
            ],
            onChanged: (value) {
              _importance = value;
              _bump();
            },
          ),
          const SizedBox(height: 10),
          _SegmentedFilter<TransactionSubscriptionFilter?>(
            label: context.l10n.searchFilterSubscription,
            value: _subscription,
            options: [
              _SegOption(context.l10n.searchFilterAll, null),
              _SegOption(
                context.l10n.searchSubscriptionYes,
                TransactionSubscriptionFilter.subscription,
              ),
              _SegOption(
                context.l10n.searchSubscriptionNo,
                TransactionSubscriptionFilter.nonSubscription,
              ),
            ],
            onChanged: (value) {
              _subscription = value;
              _bump();
            },
          ),
          if (query.trim().isEmpty)
            _RecentSearchesStrip(
              onSelected: (value) {
                query = value;
                showResults(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultsArea(
    BuildContext context,
    TransactionSearchFilter filter,
  ) {
    return FutureBuilder<List<TransactionEntry>>(
      future: ref.read(transactionSearchProvider(filter).future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 42),
            children: List.generate(5, (index) => const _SearchSkeletonRow()),
          );
        }
        if (snapshot.hasError) {
          return _SearchMessage(
            icon: Icons.error_outline_rounded,
            message: userFriendlyMessage(context, snapshot.error!),
            color: AppTheme.danger,
          );
        }

        final transactions = snapshot.data ?? const <TransactionEntry>[];
        if (transactions.isEmpty) {
          return _SearchMessage(
            icon: Icons.search_off_rounded,
            message: context.l10n.calendarSearchNoResults,
            color: context.moniaryColors.textDim,
          );
        }

        final entries = _groupByMonth(transactions);
        final locale = Localizations.localeOf(context).toString();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 42),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            if (entry is _MonthHeaderEntry) {
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 8 : 22, bottom: 8),
                child: _SectionLabel(
                  label: DateFormat.yMMMM(locale).format(entry.month),
                ),
              );
            }
            final tx = (entry as _RowEntry).transaction;
            return _SearchResultRow(
              transaction: tx,
              onTap: () => close(context, tx),
            );
          },
        );
      },
    );
  }

  /// Groups transactions by month/year (newest first); within each group,
  /// important transactions come first, then by date descending.
  List<_ListEntry> _groupByMonth(List<TransactionEntry> transactions) {
    final groups = <String, List<TransactionEntry>>{};
    final monthOf = <String, DateTime>{};
    for (final tx in transactions) {
      final date = tx.transactionDate;
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      (groups[key] ??= []).add(tx);
      monthOf[key] = DateTime(date.year, date.month);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final entries = <_ListEntry>[];
    for (final key in keys) {
      final list = groups[key]!
        ..sort((a, b) {
          if (a.isImportant != b.isImportant) {
            return b.isImportant ? 1 : -1;
          }
          return b.transactionDate.compareTo(a.transactionDate);
        });
      entries.add(_MonthHeaderEntry(monthOf[key]!));
      entries.addAll(list.map(_RowEntry.new));
    }
    return entries;
  }

  void _recordRecentSearch() {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recentSearchesProvider.notifier).add(trimmed);
    });
  }

  String _formatAmount(double amount) => formatCurrency(
    amount,
    currencyCode: ref.read(preferredCurrencyProvider),
    locale: ref.read(preferredLocaleProvider),
  );

  String? _dateLabel() {
    final format = DateFormat('dd/MM/yy');
    if (_dateFrom != null && _dateTo != null) {
      return '${format.format(_dateFrom!)} – ${format.format(_dateTo!)}';
    }
    if (_dateFrom != null) return '≥ ${format.format(_dateFrom!)}';
    if (_dateTo != null) return '≤ ${format.format(_dateTo!)}';
    return null;
  }

  String? _amountLabel() {
    if (_minAmount != null && _maxAmount != null) {
      return '${_formatAmount(_minAmount!)} – ${_formatAmount(_maxAmount!)}';
    }
    if (_minAmount != null) return '≥ ${_formatAmount(_minAmount!)}';
    if (_maxAmount != null) return '≤ ${_formatAmount(_maxAmount!)}';
    return null;
  }

  void _clearFilters() {
    _type = null;
    _importance = null;
    _subscription = null;
    _categoryId = null;
    _categoryName = null;
    _dateFrom = null;
    _dateTo = null;
    _minAmount = null;
    _maxAmount = null;
    _bump();
  }

  Future<void> _pickCategory(BuildContext context) async {
    final categories =
        ref.read(categoriesControllerProvider).value ?? const <Category>[];
    final active = categories.where((c) => c.isActive).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final selected = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.moniaryColors.backgroundSoft,
      builder: (sheetContext) => _OptionSheet(
        title: sheetContext.l10n.searchFilterCategory,
        options: [
          _SheetOption(
            label: sheetContext.l10n.searchFilterAllCategories,
            value: const _CategoryChoice(null, null),
            selected: _categoryId == null,
          ),
          ...active.map(
            (category) => _SheetOption(
              label: category.name,
              value: _CategoryChoice(category.id, category.name),
              selected: _categoryId == category.id,
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    _categoryId = selected.id;
    _categoryName = selected.name;
    _bump();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (picked == null) return;
    _dateFrom = picked.start;
    _dateTo = picked.end;
    _bump();
  }

  Future<void> _pickAmountRange(BuildContext context) async {
    final result = await showModalBottomSheet<_AmountRange>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.moniaryColors.backgroundSoft,
      builder: (sheetContext) =>
          _AmountRangeSheet(initialMin: _minAmount, initialMax: _maxAmount),
    );
    if (result == null) return;
    _minAmount = result.min;
    _maxAmount = result.max;
    _bump();
  }

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );
}

sealed class _ListEntry {
  const _ListEntry();
}

class _MonthHeaderEntry extends _ListEntry {
  const _MonthHeaderEntry(this.month);
  final DateTime month;
}

class _RowEntry extends _ListEntry {
  const _RowEntry(this.transaction);
  final TransactionEntry transaction;
}

class _CategoryChoice {
  const _CategoryChoice(this.id, this.name);
  final String? id;
  final String? name;
}

class _AmountRange {
  const _AmountRange(this.min, this.max);
  final double? min;
  final double? max;
}

class _FilterScrollRow extends StatefulWidget {
  const _FilterScrollRow({required this.children});

  final List<Widget> children;

  @override
  State<_FilterScrollRow> createState() => _FilterScrollRowState();
}

class _FilterScrollRowState extends State<_FilterScrollRow> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // Positions aren't measured until after first layout; rebuild once so the
    // scroll indicator reflects real dimensions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Center(
              child: widget.children[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ScrollIndicator(controller: _controller),
      ],
    );
  }
}

class _ScrollIndicator extends StatelessWidget {
  const _ScrollIndicator({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (!controller.hasClients ||
                !controller.position.hasContentDimensions) {
              return const SizedBox(height: 3);
            }
            final position = controller.position;
            if (position.maxScrollExtent <= 0) {
              // Nothing to scroll — no indicator needed.
              return const SizedBox(height: 3);
            }
            final content = position.maxScrollExtent + position.viewportDimension;
            final thumbWidth = (trackWidth * position.viewportDimension / content)
                .clamp(28.0, trackWidth);
            final t = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
            final left = (trackWidth - thumbWidth) * t;
            return SizedBox(
              height: 3,
              width: trackWidth,
              child: Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: left,
                    child: Container(
                      width: thumbWidth,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SegOption<T> {
  const _SegOption(this.label, this.value);
  final String label;
  final T value;
}

class _SegmentedFilter<T> extends StatelessWidget {
  const _SegmentedFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_SegOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 66,
          child: Text(
            label.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: context.moniaryColors.textDim,
              fontSize: 8.5,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options
                .map(
                  (option) => _SearchChip(
                    label: option.label,
                    compact: true,
                    selected: option.value == value,
                    onTap: () => onChanged(option.value),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _FilterEntryChip extends StatelessWidget {
  const _FilterEntryChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Material(
      color: active
          ? colors.primary.withValues(alpha: 0.12)
          : _controlFill(colors),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? colors.primary : _searchBorder(colors),
          width: 1.15,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? colors.primary : colors.textDim,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active ? colors.primary : colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: active ? colors.primary : colors.textDim,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchesStrip extends ConsumerWidget {
  const _RecentSearchesStrip({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    if (recent.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionLabel(label: context.l10n.calendarRecentSearches),
              GestureDetector(
                onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: Text(
                  context.l10n.searchRecentClear,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: AppTheme.terracotta,
                    fontSize: 8.5,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map(
                  (value) => _SearchChip(
                    label: value,
                    selected: false,
                    onTap: () => onSelected(value),
                    onRemove: () =>
                        ref.read(recentSearchesProvider.notifier).remove(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({required this.title, required this.options});

  final String title;
  final List<_SheetOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 0, 23, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: options
                    .map(
                      (option) => ListTile(
                        title: Text(option.label),
                        trailing: option.selected
                            ? Icon(Icons.check_rounded, color: colors.primary)
                            : null,
                        onTap: () => Navigator.pop(context, option.value),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption<T> {
  const _SheetOption({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final T value;
  final bool selected;
}

class _AmountRangeSheet extends StatefulWidget {
  const _AmountRangeSheet({this.initialMin, this.initialMax});

  final double? initialMin;
  final double? initialMax;

  @override
  State<_AmountRangeSheet> createState() => _AmountRangeSheetState();
}

class _AmountRangeSheetState extends State<_AmountRangeSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  String? _error;

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(
      text: widget.initialMin?.toStringAsFixed(0) ?? '',
    );
    _max = TextEditingController(
      text: widget.initialMax?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_min.text.trim());
    final max = double.tryParse(_max.text.trim());
    if (min != null && max != null && max < min) {
      setState(() => _error = context.l10n.searchAmountRangeError);
      return;
    }
    Navigator.pop(context, _AmountRange(min, max));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(23, 0, 23, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.searchFilterAmount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: context.l10n.searchFilterAmountMin,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: context.l10n.searchFilterAmountMax,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                color: context.moniaryColors.danger,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, const _AmountRange(null, null)),
                  child: Text(context.l10n.searchFilterClearAll),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: Text(context.l10n.searchFilterApply),
                ),
              ),
            ],
          ),
        ],
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

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final VoidCallback? onRemove;

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
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.surfaceRaised : colors.textSecondary,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: colors.textDim,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultRow extends ConsumerWidget {
  const _SearchResultRow({required this.transaction, required this.onTap});

  final TransactionEntry transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final title = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : transaction.categoryName.trim().isEmpty
        ? context.l10n.categoryOther
        : transaction.categoryName;
    final amountColor = transaction.isIncome
        ? colors.success
        : colors.textPrimary;

    return Column(
      children: [
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
                          '${(transaction.walletName.trim().isEmpty ? context.l10n.walletUnknown : transaction.walletName).toUpperCase()}',
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
                        '${transaction.isIncome ? '+' : '-'}${ref.formatAmount(transaction.amount)}',
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
