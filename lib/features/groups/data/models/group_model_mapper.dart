import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';

class GroupModelMapper {
  const GroupModelMapper._();

  static SpendingGroup group(
    Map<String, dynamic> row, {
    int memberCount = 0,
    int totalSpent = 0,
    int currentUserBalance = 0,
    bool hasUnresolvedSettlements = false,
  }) {
    return SpendingGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      avatarPath: row['avatar_path'] as String?,
      description: row['description'] as String?,
      type: row['type'] as String?,
      createdBy: row['created_by'] as String,
      status: GroupStatusValue.fromValue(row['status'] as String? ?? 'active'),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      memberCount: memberCount,
      totalSpent: totalSpent,
      currentUserBalance: currentUserBalance,
      hasUnresolvedSettlements: hasUnresolvedSettlements,
    );
  }

  static SpendingGroupMember member(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return SpendingGroupMember(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      userId: row['user_id'] as String,
      role: GroupRoleValue.fromValue(row['role'] as String),
      status: GroupMemberStatusValue.fromValue(row['status'] as String),
      joinedAt: _date(row['joined_at']),
      leftAt: _nullableDate(row['left_at']),
      displayName: profile?['full_name'] as String?,
      username: profile?['username'] as String?,
      avatarPath: profile?['avatar_url'] as String?,
    );
  }

  static GroupTransaction transaction(Map<String, dynamic> row) {
    final creator = row['creator'] as Map<String, dynamic>?;
    return GroupTransaction(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      createdBy: row['created_by'] as String,
      totalAmount: _money(row['total_amount']),
      categoryId: row['category_id'] as String?,
      categoryName: row['category_name_snapshot'] as String?,
      caption: row['caption'] as String?,
      note: row['note'] as String?,
      imagePath: row['image_path'] as String?,
      imageUploadStatus: GroupImageUploadStatusValue.fromValue(
        row['image_upload_status'] as String? ?? 'pending',
      ),
      splitMode: GroupSplitModeValue.fromValue(row['split_mode'] as String),
      paymentMode: GroupPaymentModeValue.fromValue(
        row['payment_mode'] as String,
      ),
      splitStatus: GroupSplitStatusValue.fromValue(
        row['split_status'] as String,
      ),
      transactionDate: _date(row['transaction_date']),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      creatorName: creator?['full_name'] as String?,
      hasCompletedSettlement: row['has_completed_settlement'] as bool? ?? false,
    );
  }

  static GroupTransactionPayer payer(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return GroupTransactionPayer(
      id: row['id'] as String,
      groupTransactionId: row['group_transaction_id'] as String,
      userId: row['user_id'] as String,
      paidAmount: _money(row['paid_amount']),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      displayName: profile?['full_name'] as String?,
    );
  }

  static GroupTransactionShare share(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return GroupTransactionShare(
      id: row['id'] as String,
      groupTransactionId: row['group_transaction_id'] as String,
      userId: row['user_id'] as String,
      shareAmount: _money(row['share_amount']),
      inputStatus: GroupShareInputStatusValue.fromValue(
        row['input_status'] as String,
      ),
      submittedAt: _nullableDate(row['submitted_at']),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      displayName: profile?['full_name'] as String?,
    );
  }

  static GroupTransactionComment comment(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return GroupTransactionComment(
      id: row['id'] as String,
      groupTransactionId: row['group_transaction_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      displayName: profile?['full_name'] as String?,
      avatarPath: profile?['avatar_url'] as String?,
    );
  }

  static GroupBalance balance(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>?;
    return GroupBalance(
      groupId: row['group_id'] as String,
      userId: row['user_id'] as String,
      totalShareAmount: _money(row['total_share_amount']),
      totalPaidAmount: _money(row['total_paid_amount']),
      balance: _money(row['balance']),
      displayName: profile?['full_name'] as String?,
    );
  }

  static GroupSettlementSuggestion settlement(Map<String, dynamic> row) {
    final fromProfile = row['from_profile'] as Map<String, dynamic>?;
    final toProfile = row['to_profile'] as Map<String, dynamic>?;
    return GroupSettlementSuggestion(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      fromUserId: row['from_user_id'] as String,
      toUserId: row['to_user_id'] as String,
      amount: _money(row['amount']),
      status: GroupSettlementStatusValue.fromValue(row['status'] as String),
      payerMarkedPaidAt: _nullableDate(row['payer_marked_paid_at']),
      receiverConfirmedAt: _nullableDate(row['receiver_confirmed_at']),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      fromDisplayName: fromProfile?['full_name'] as String?,
      toDisplayName: toProfile?['full_name'] as String?,
    );
  }

  static int _money(dynamic value) => (value as num?)?.toInt() ?? 0;

  static DateTime _date(dynamic value) =>
      DateTime.parse(value as String).toLocal();

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
