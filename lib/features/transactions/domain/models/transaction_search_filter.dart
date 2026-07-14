import '../../../categories/domain/models/category.dart';

/// Importance facet of a search: null means "all", otherwise restrict to
/// important-only or not-important-only.
enum TransactionImportanceFilter { important, notImportant }

/// Immutable description of a transaction search: free text plus optional
/// structured filters. Used as a Riverpod family key, so it implements value
/// equality.
class TransactionSearchFilter {
  const TransactionSearchFilter({
    this.query = '',
    this.type,
    this.categoryId,
    this.dateFrom,
    this.dateTo,
    this.minAmount,
    this.maxAmount,
    this.importance,
  });

  final String query;
  final TransactionType? type;
  final String? categoryId;

  /// Inclusive lower/upper day bounds (time component ignored).
  final DateTime? dateFrom;
  final DateTime? dateTo;

  final double? minAmount;
  final double? maxAmount;
  final TransactionImportanceFilter? importance;

  bool get hasActiveFilters =>
      type != null ||
      categoryId != null ||
      dateFrom != null ||
      dateTo != null ||
      minAmount != null ||
      maxAmount != null ||
      importance != null;

  @override
  bool operator ==(Object other) =>
      other is TransactionSearchFilter &&
      other.query == query &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.importance == importance;

  @override
  int get hashCode => Object.hash(
    query,
    type,
    categoryId,
    dateFrom,
    dateTo,
    minAmount,
    maxAmount,
    importance,
  );
}
