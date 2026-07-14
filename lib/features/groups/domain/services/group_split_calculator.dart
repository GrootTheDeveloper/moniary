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
  participantNotActive,
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

  void validateDraft({
    required int totalAmount,
    required List<String> activeMemberIds,
    required GroupSplitMode splitMode,
    required GroupPaymentMode paymentMode,
    List<String>? participantIds,
    Map<String, int> shareAmounts = const {},
    Map<String, int> payerAmounts = const {},
  }) {
    final participants = participantIds?.toSet().toList() ?? activeMemberIds;
    _validateParticipants(
      totalAmount: totalAmount,
      activeMemberIds: activeMemberIds,
      participantIds: participants,
    );
    if (splitMode != GroupSplitMode.unequal) {
      calculate(
        totalAmount: totalAmount,
        activeMemberIds: activeMemberIds,
        participantIds: participants,
        splitMode: splitMode,
        paymentMode: paymentMode,
        unequalShares: shareAmounts,
        payerAmounts: payerAmounts,
      );
      return;
    }
    _calculatePaidAmounts(
      totalAmount: totalAmount,
      shares: {for (final memberId in activeMemberIds) memberId: 0},
      activeMembers: activeMemberIds.toSet(),
      paymentMode: paymentMode,
      payerAmounts: payerAmounts,
    );
  }

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
    List<String>? participantIds,
    Map<String, int>? unequalShares,
    Set<String>? submittedMemberIds,
    Map<String, int> payerAmounts = const {},
  }) {
    final participants = participantIds?.toSet().toList() ?? activeMemberIds;
    _validateParticipants(
      totalAmount: totalAmount,
      activeMemberIds: activeMemberIds,
      participantIds: participants,
    );
    final activeMembers = activeMemberIds.toSet();
    final shares = switch (splitMode) {
      GroupSplitMode.equal => calculateEqualShares(
        totalAmount: totalAmount,
        activeMemberIds: participants,
      ),
      GroupSplitMode.exact => _validateExactShares(
        totalAmount: totalAmount,
        participantIds: participants,
        shares: unequalShares,
      ),
      GroupSplitMode.unequal => _validateUnequalShares(
        totalAmount: totalAmount,
        activeMemberIds: participants,
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
        memberId: (shares[memberId] ?? 0) - paidAmounts[memberId]!,
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

  void _validateParticipants({
    required int totalAmount,
    required List<String> activeMemberIds,
    required List<String> participantIds,
  }) {
    _validateBase(totalAmount, participantIds);
    final active = activeMemberIds.toSet();
    if (participantIds.any((id) => !active.contains(id))) {
      throw const GroupSplitException(GroupSplitError.participantNotActive);
    }
  }

  Map<String, int> _validateExactShares({
    required int totalAmount,
    required List<String> participantIds,
    required Map<String, int>? shares,
  }) {
    final exactShares = {
      for (final participantId in participantIds)
        participantId: shares?[participantId] ?? -1,
    };
    if (exactShares.values.any((amount) => amount < 0) ||
        exactShares.values.fold<int>(0, (sum, amount) => sum + amount) !=
            totalAmount ||
        shares?.keys.any((id) => !exactShares.containsKey(id)) == true) {
      throw const GroupSplitException(GroupSplitError.shareTotalMismatch);
    }
    return exactShares;
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
      return {
        for (final memberId in activeMembers) memberId: shares[memberId] ?? 0,
      };
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
