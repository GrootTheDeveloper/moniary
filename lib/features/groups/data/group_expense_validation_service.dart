import '../../../l10n/gen_l10n/app_localizations.dart';
import '../domain/expense_group.dart';
import '../domain/expense_split.dart';

enum SplitMethod { equal, manual }

extension SplitMethodX on SplitMethod {
  String getLabel(AppLocalizations l10n) => switch (this) {
        SplitMethod.equal => l10n.expenseSplitEqual,
        SplitMethod.manual => l10n.expenseSplitManual,
      };
}

enum GroupExpenseValidationError {
  minMembers,
  amountPositive,
  selectPayer,
  selectParticipant,
  invalidParticipants,
  splitCountMismatch,
  negativeSplit,
  splitMismatch,
}

class GroupExpenseValidationService {
  const GroupExpenseValidationService();

  List<ExpenseSplit> createEqualSplits({
    required double amount,
    required List<String> participantIds,
  }) {
    if (amount <= 0 || participantIds.isEmpty) {
      return const [];
    }
    final wholeAmount = amount.round();
    final base = wholeAmount ~/ participantIds.length;
    var remainder = wholeAmount - (base * participantIds.length);
    return participantIds.map((memberId) {
      final share = base + (remainder > 0 ? 1 : 0);
      if (remainder > 0) {
        remainder--;
      }
      return ExpenseSplit(memberId: memberId, amount: share.toDouble());
    }).toList();
  }

  GroupExpenseValidationError? validate({
    required ExpenseGroup group,
    required double amount,
    required String? payerMemberId,
    required List<String> participantIds,
    required List<ExpenseSplit> splits,
  }) {
    if (group.members.length < 2) {
      return GroupExpenseValidationError.minMembers;
    }
    if (amount <= 0) {
      return GroupExpenseValidationError.amountPositive;
    }
    final members = group.members.map((member) => member.id).toSet();
    if (payerMemberId == null || !members.contains(payerMemberId)) {
      return GroupExpenseValidationError.selectPayer;
    }
    if (participantIds.isEmpty) {
      return GroupExpenseValidationError.selectParticipant;
    }
    if (participantIds.any((id) => !members.contains(id))) {
      return GroupExpenseValidationError.invalidParticipants;
    }
    if (participantIds.toSet().length != participantIds.length ||
        splits.map((split) => split.memberId).toSet().length != splits.length ||
        !participantIds.toSet().containsAll(
              splits.map((split) => split.memberId),
            ) ||
        !splits
            .map((split) => split.memberId)
            .toSet()
            .containsAll(participantIds)) {
      return GroupExpenseValidationError.splitCountMismatch;
    }
    if (splits.any((split) => split.amount < 0)) {
      return GroupExpenseValidationError.negativeSplit;
    }
    final splitTotal = splits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    if ((splitTotal - amount).abs() > 0.01) {
      return GroupExpenseValidationError.splitMismatch;
    }
    return null;
  }
}
