class CalendarFilters {
  const CalendarFilters({this.walletId, this.categoryId});

  final String? walletId;
  final String? categoryId;

  CalendarFilters copyWith({
    String? walletId,
    String? categoryId,
    bool clearWallet = false,
    bool clearCategory = false,
  }) {
    return CalendarFilters(
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }

  bool get isEmpty => walletId == null && categoryId == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarFilters &&
        other.walletId == walletId &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(walletId, categoryId);
}
