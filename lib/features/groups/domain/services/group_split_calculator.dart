import '../entities/group_enums.dart';

enum GroupSplitError {
  totalAmountNotPositive,
  noActiveMembers,
  pendingMemberInput,
  shareTotalMismatch,
  payerRequired,
  multiplePayersRequired,
  payerAmountRequired,
  payerAmountNotPositive,
  paidTotalMismatch,
  payerNotActive,
}

class GroupSplitException implements Exception {
  const GroupSplitException(this.error);

  final GroupSplitError error;
}

class GroupSplitResult {
  const GroupSplitResult({
    required this.shares,
    required this.paidAmounts,
    required this.balances,
  });

  final Map<String, int> shares;
  final Map<String, int> paidAmounts;
  final Map<String, int> balances;
}

class GroupSplitCalculator {
  const GroupSplitCalculator();

  Map<String, int> calculateEqualShares({
    required int totalAmount,
    required List<String> activeMemberIds,
  }) {
    _validateBase(totalAmount, activeMemberIds);
    final stableMembers = [...activeMemberIds]..sort();
    final baseShare = totalAmount ~/ stableMembers.length;
    final remainder = totalAmount % stableMembers.length;
    return {
      for (var index = 0; index < stableMembers.length; index++)
        stableMembers[index]: baseShare + (index < remainder ? 1 : 0),
    };
  }

  GroupSplitResult calculate({
    required int totalAmount,
    required List<String> activeMemberIds,
    required GroupSplitMode splitMode,
    required GroupPaymentMode paymentMode,
    Map<String, int>? unequalShares,
    Set<String>? submittedMemberIds,
    Map<String, int> payerAmounts = const {},
  }) {
    _validateBase(totalAmount, activeMemberIds);
    final activeMembers = activeMemberIds.toSet();
    final shares = switch (splitMode) {
      GroupSplitMode.equal => calculateEqualShares(
        totalAmount: totalAmount,
        activeMemberIds: activeMemberIds,
      ),
      GroupSplitMode.unequal => _validateUnequalShares(
        totalAmount: totalAmount,
        activeMemberIds: activeMemberIds,
        unequalShares: unequalShares,
        submittedMemberIds: submittedMemberIds,
      ),
    };

    final paidAmounts = _calculatePaidAmounts(
      totalAmount: totalAmount,
      shares: shares,
      activeMembers: activeMembers,
      paymentMode: paymentMode,
      payerAmounts: payerAmounts,
    );
    final balances = {
      for (final memberId in activeMemberIds)
        memberId: shares[memberId]! - paidAmounts[memberId]!,
    };

    return GroupSplitResult(
      shares: Map.unmodifiable(shares),
      paidAmounts: Map.unmodifiable(paidAmounts),
      balances: Map.unmodifiable(balances),
    );
  }

  void _validateBase(int totalAmount, List<String> activeMemberIds) {
    if (totalAmount <= 0) {
      throw const GroupSplitException(GroupSplitError.totalAmountNotPositive);
    }
    if (activeMemberIds.isEmpty) {
      throw const GroupSplitException(GroupSplitError.noActiveMembers);
    }
  }

  Map<String, int> _validateUnequalShares({
    required int totalAmount,
    required List<String> activeMemberIds,
    required Map<String, int>? unequalShares,
    required Set<String>? submittedMemberIds,
  }) {
    final submitted = submittedMemberIds ?? unequalShares?.keys.toSet() ?? {};
    if (!submitted.containsAll(activeMemberIds)) {
      throw const GroupSplitException(GroupSplitError.pendingMemberInput);
    }
    final shares = {
      for (final memberId in activeMemberIds)
        memberId: unequalShares?[memberId] ?? 0,
    };
    if (shares.values.any((amount) => amount < 0) ||
        shares.values.fold<int>(0, (sum, amount) => sum + amount) !=
            totalAmount) {
      throw const GroupSplitException(GroupSplitError.shareTotalMismatch);
    }
    return shares;
  }

  Map<String, int> _calculatePaidAmounts({
    required int totalAmount,
    required Map<String, int> shares,
    required Set<String> activeMembers,
    required GroupPaymentMode paymentMode,
    required Map<String, int> payerAmounts,
  }) {
    if (paymentMode == GroupPaymentMode.everyonePaid) {
      return Map<String, int>.from(shares);
    }
    if (payerAmounts.keys.any((id) => !activeMembers.contains(id))) {
      throw const GroupSplitException(GroupSplitError.payerNotActive);
    }
    if (paymentMode == GroupPaymentMode.singlePayer &&
        payerAmounts.length != 1) {
      throw const GroupSplitException(GroupSplitError.payerRequired);
    }
    if (paymentMode == GroupPaymentMode.multiplePayers &&
        payerAmounts.length < 2) {
      throw const GroupSplitException(GroupSplitError.multiplePayersRequired);
    }
    if (payerAmounts.isEmpty) {
      throw const GroupSplitException(GroupSplitError.payerAmountRequired);
    }
    if (payerAmounts.values.any((amount) => amount <= 0)) {
      throw const GroupSplitException(GroupSplitError.payerAmountNotPositive);
    }
    if (payerAmounts.values.fold<int>(0, (sum, amount) => sum + amount) !=
        totalAmount) {
      throw const GroupSplitException(GroupSplitError.paidTotalMismatch);
    }
    return {
      for (final memberId in activeMembers)
        memberId: payerAmounts[memberId] ?? 0,
    };
  }
}
