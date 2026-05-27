import '../domain/expense_group.dart';
import '../domain/expense_split.dart';

enum SplitMethod { equal, manual }

extension SplitMethodX on SplitMethod {
  String get label => switch (this) {
    SplitMethod.equal => 'Chia đều',
    SplitMethod.manual => 'Tự nhập số tiền',
  };
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

  String? validate({
    required ExpenseGroup group,
    required double amount,
    required String? payerMemberId,
    required List<String> participantIds,
    required List<ExpenseSplit> splits,
  }) {
    if (group.members.length < 2) {
      return 'Nhóm cần ít nhất 2 thành viên để chia chi phí.';
    }
    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0.';
    }
    final members = group.members.map((member) => member.id).toSet();
    if (payerMemberId == null || !members.contains(payerMemberId)) {
      return 'Vui lòng chọn người đã thanh toán.';
    }
    if (participantIds.isEmpty) {
      return 'Chọn ít nhất một người tham gia.';
    }
    if (participantIds.any((id) => !members.contains(id))) {
      return 'Danh sách người tham gia không hợp lệ.';
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
      return 'Mỗi người tham gia cần đúng một phần chia.';
    }
    if (splits.any((split) => split.amount < 0)) {
      return 'Số tiền chia không được âm.';
    }
    final splitTotal = splits.fold<double>(
      0,
      (sum, split) => sum + split.amount,
    );
    if ((splitTotal - amount).abs() > 0.01) {
      return 'Tổng phần chia phải bằng tổng chi phí.';
    }
    return null;
  }
}
