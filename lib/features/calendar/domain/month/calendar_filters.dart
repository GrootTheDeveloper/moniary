class CalendarFilters {
  const CalendarFilters({this.walletId, this.categoryId, this.isStarredOnly = false});

  final String? walletId;
  final String? categoryId;
  final bool isStarredOnly;

  CalendarFilters copyWith({
    String? walletId,
    String? categoryId,
    bool? isStarredOnly,
    bool clearWallet = false,
    bool clearCategory = false,
  }) {
    return CalendarFilters(
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isStarredOnly: isStarredOnly ?? this.isStarredOnly,
    );
  }

  bool get isEmpty => walletId == null && categoryId == null && !isStarredOnly;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarFilters &&
        other.walletId == walletId &&
        other.categoryId == categoryId &&
        other.isStarredOnly == isStarredOnly;
  }

  @override
  int get hashCode => Object.hash(walletId, categoryId, isStarredOnly);
}
