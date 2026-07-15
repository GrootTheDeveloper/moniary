import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';

class GroupModelMapper {
  const GroupModelMapper._();

  static SpendingGroup group(
    Map<String, dynamic> row, {
    int memberCount = 0,
    List<String?> memberAvatarPaths = const [],
    int transactionCount = 0,
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
      memberAvatarPaths: memberAvatarPaths,
      transactionCount: transactionCount,
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

  static GroupReactionSummary reaction(Map<String, dynamic> row) {
    return GroupReactionSummary(
      emoji: row['emoji'] as String,
      count: (row['reaction_count'] as num).toInt(),
      reactedByCurrentUser: row['reacted_by_current_user'] as bool? ?? false,
    );
  }

  static GroupNotification notification(Map<String, dynamic> row) {
    return GroupNotification(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      groupName: row['group_name'] as String? ?? '',
      groupTransactionId: row['group_transaction_id'] as String?,
      inviteToken: row['invite_token'] as String?,
      category: row['category'] as String? ?? 'group',
      type: row['type'] as String,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: _date(row['created_at']),
    );
  }

  static GroupActivity activity(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    return GroupActivity(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      actorUserId: row['actor_user_id'] as String,
      actorName: row['actor_name'] as String?,
      type: row['type'] as String,
      metadata: metadata is Map
          ? Map<String, dynamic>.from(metadata)
          : const <String, dynamic>{},
      createdAt: _date(row['created_at']),
    );
  }

  static GroupNotificationPreference notificationPreference(
    Map<String, dynamic> row,
  ) {
    final groupId = row['group_id'] as String;
    return GroupNotificationPreference(
      groupId: groupId,
      muteAll: row['mute_all'] as bool? ?? false,
      transactionNotifications:
          row['transaction_notifications'] as bool? ?? true,
      debtNotifications: row['debt_notifications'] as bool? ?? true,
      inviteNotifications: row['invite_notifications'] as bool? ?? true,
      mentionNotifications: row['mention_notifications'] as bool? ?? true,
      communityComments: row['community_comments'] as bool? ?? true,
      communityReactions: row['community_reactions'] as bool? ?? true,
      quietHoursStart: _nullableInt(row['quiet_hours_start']),
      quietHoursEnd: _nullableInt(row['quiet_hours_end']),
    );
  }

  static GroupReactionSummary reactionSummary(Map<String, dynamic> row) {
    return GroupReactionSummary(
      emoji: row['emoji'] as String,
      count: _money(row['reaction_count']),
      reactedByCurrentUser: row['reacted_by_current_user'] as bool? ?? false,
    );
  }

  static GroupBudget budget(Map<String, dynamic> row) {
    final groupId = row['group_id'] as String;
    return GroupBudget(
      groupId: groupId,
      monthlyLimit: _money(row['monthly_limit']),
      warningThresholdPercent:
          (row['warning_threshold_percent'] as num?)?.toInt() ?? 80,
    );
  }

  static GroupRecurringTransaction recurringTransaction(
    Map<String, dynamic> row,
  ) {
    return GroupRecurringTransaction(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      createdBy: row['created_by'] as String,
      title: row['title'] as String,
      amount: _money(row['amount']),
      frequency: row['frequency'] as String? ?? 'monthly',
      nextRunAt: _date(row['next_run_at']),
      notifyDaysBefore: (row['notify_days_before'] as num?)?.toInt() ?? 1,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: _date(row['created_at']),
    );
  }

  static GroupPublicProfile publicProfile(Map<String, dynamic> row) {
    final groupId = row['group_id'] as String;
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: row['is_enabled'] as bool? ?? false,
      showStats: row['show_stats'] as bool? ?? false,
      slug: row['slug'] as String?,
    );
  }

  static int _money(dynamic value) => (value as num?)?.toInt() ?? 0;

  static int? _nullableInt(dynamic value) => (value as num?)?.toInt();

  static DateTime _date(dynamic value) =>
      DateTime.parse(value as String).toLocal();

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
