import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/services/group_split_calculator.dart';
import '../../domain/services/settlement_calculator.dart';

class GroupMockDataSource {
  GroupMockDataSource({required this.currentUserId});

  final String currentUserId;
  final GroupSplitCalculator _splitCalculator = const GroupSplitCalculator();
  final SettlementCalculator _settlementCalculator =
      const SettlementCalculator();

  static final Map<String, SpendingGroup> _groups = {};
  static final Map<String, List<SpendingGroupMember>> _members = {};
  static final Map<String, _MockTransactionRecord> _transactions = {};
  static final Map<String, List<GroupSettlementSuggestion>> _settlements = {};
  static final Map<String, _MockGroupInvite> _invites = {};
  static final Map<String, List<GroupNotification>> _notifications = {};
  static final Map<String, List<GroupActivity>> _activities = {};
  static var _sequence = 0;

  Future<List<SpendingGroup>> fetchGroups() async {
    final memberGroupIds = _members.entries
        .where(
          (entry) => entry.value.any(
            (member) =>
                member.userId == currentUserId &&
                member.status == GroupMemberStatus.active,
          ),
        )
        .map((entry) => entry.key)
        .toSet();
    final result =
        _groups.values.where((group) => memberGroupIds.contains(group.id)).map((
          group,
        ) {
          final groupTransactions = _recordsForGroup(group.id);
          final balance = _groupBalances(group.id)[currentUserId] ?? 0;
          return group.copyWith(
            memberCount: _activeMembers(group.id).length,
            totalSpent: groupTransactions
                .where(
                  (record) =>
                      record.transaction.splitStatus == GroupSplitStatus.posted,
                )
                .fold<int>(
                  0,
                  (sum, record) => sum + record.transaction.totalAmount,
                ),
            currentUserBalance: balance,
            hasUnresolvedSettlements:
                _settlements[group.id]?.any(
                  (item) =>
                      item.status == GroupSettlementStatus.pending ||
                      item.status == GroupSettlementStatus.payerMarkedPaid,
                ) ??
                false,
          );
        }).toList()..sort(
          (left, right) => right.updatedAt.compareTo(left.updatedAt),
        );
    return List.unmodifiable(result);
  }

  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) async {
    final group = _requireGroup(groupId);
    final members = List<SpendingGroupMember>.unmodifiable(
      _members[groupId] ?? const [],
    );
    final current = members.where(
      (member) =>
          member.userId == currentUserId &&
          member.status == GroupMemberStatus.active,
    );
    if (current.isEmpty) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    return SpendingGroupDetail(
      group: group.copyWith(memberCount: _activeMembers(groupId).length),
      members: members,
      currentUserRole: current.first.role,
    );
  }

  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException(
        'Group name required',
        code: 'GROUP_NAME_REQUIRED',
      );
    }
    final id = _id('group');
    final now = DateTime.now();
    _groups[id] = SpendingGroup(
      id: id,
      name: trimmedName,
      description: _blankToNull(description),
      type: _blankToNull(type),
      createdBy: currentUserId,
      status: GroupStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    _members[id] = [
      SpendingGroupMember(
        id: _id('member'),
        groupId: id,
        userId: currentUserId,
        role: GroupRole.owner,
        status: GroupMemberStatus.active,
        joinedAt: now,
        displayName: 'mock-user',
        username: 'mock-user',
      ),
    ];
    return id;
  }

  Future<String> createInviteLink(String groupId) async {
    _requireAdmin(groupId);
    final token = _id('invite');
    _invites[token] = _MockGroupInvite(
      token: token,
      groupId: groupId,
      invitedBy: currentUserId,
      status: GroupInviteStatus.pending,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    return AppConstants.groupInviteLink(token);
  }

  Future<GroupInvitePreview> fetchInvitePreview(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null) {
      return const GroupInvitePreview(
        status: GroupInviteStatus.invalid,
        memberCount: 0,
      );
    }
    final group = _groups[invite.groupId];
    if (group == null || group.status == GroupStatus.archived) {
      return GroupInvitePreview(
        status: group == null
            ? GroupInviteStatus.invalid
            : GroupInviteStatus.groupArchived,
        memberCount: 0,
        expiresAt: invite.expiresAt,
      );
    }
    final isActiveMember =
        _members[invite.groupId]?.any(
          (member) =>
              member.userId == currentUserId &&
              member.status == GroupMemberStatus.active,
        ) ??
        false;
    final status = isActiveMember
        ? GroupInviteStatus.alreadyMember
        : invite.expiresAt.isBefore(DateTime.now())
        ? GroupInviteStatus.expired
        : invite.status;
    return GroupInvitePreview(
      status: status,
      groupId: group.id,
      groupName: group.name,
      avatarPath: group.avatarPath,
      description: group.description,
      type: group.type,
      invitedBy: invite.invitedBy,
      inviterName: _displayName(invite.groupId, invite.invitedBy),
      memberCount: _activeMembers(invite.groupId).length,
      expiresAt: invite.expiresAt,
    );
  }

  Future<GroupInviteAcceptResult> acceptInvite(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null) {
      throw const AppException(
        'Invalid group invite',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    if (invite.invitedUserId != null && invite.invitedUserId != currentUserId) {
      throw const AppException(
        'Group invite forbidden',
        code: 'GROUP_INVITE_FORBIDDEN',
      );
    }
    final group = _groups[invite.groupId];
    if (group == null) {
      throw const AppException(
        'Invalid group invite',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    if (invite.status != GroupInviteStatus.pending) {
      throw const AppException(
        'Group invite is not pending',
        code: 'GROUP_INVITE_NOT_PENDING',
      );
    }
    if (invite.expiresAt.isBefore(DateTime.now())) {
      invite.status = GroupInviteStatus.expired;
      throw const AppException(
        'Group invite expired',
        code: 'GROUP_INVITE_EXPIRED',
      );
    }
    final members = _members[invite.groupId] ?? [];
    final existingIndex = members.indexWhere(
      (member) => member.userId == currentUserId,
    );
    if (existingIndex != -1 &&
        members[existingIndex].status == GroupMemberStatus.active) {
      return GroupInviteAcceptResult(
        status: GroupInviteAcceptStatus.alreadyMember,
        groupId: invite.groupId,
      );
    }
    final now = DateTime.now();
    if (existingIndex == -1) {
      members.add(
        SpendingGroupMember(
          id: _id('member'),
          groupId: invite.groupId,
          userId: currentUserId,
          role: GroupRole.member,
          status: GroupMemberStatus.active,
          joinedAt: now,
          displayName: 'mock-user',
          username: 'mock-user',
        ),
      );
      _members[invite.groupId] = members;
    } else {
      final member = members[existingIndex];
      members[existingIndex] = SpendingGroupMember(
        id: member.id,
        groupId: member.groupId,
        userId: member.userId,
        role: member.role == GroupRole.owner
            ? GroupRole.owner
            : GroupRole.member,
        status: GroupMemberStatus.active,
        joinedAt: member.joinedAt,
        leftAt: null,
        displayName: member.displayName,
        username: member.username,
        avatarPath: member.avatarPath,
      );
    }
    invite.status = GroupInviteStatus.accepted;
    _recordActivity(invite.groupId, 'member_joined');
    _notifyActiveMembers(
      invite.groupId,
      'member_joined',
      excludeCurrentUser: true,
    );
    return GroupInviteAcceptResult(
      status: GroupInviteAcceptStatus.accepted,
      groupId: invite.groupId,
    );
  }

  Future<void> declineInvite(String token) async {
    final invite = _invites[token.trim()];
    if (invite == null) {
      throw const AppException(
        'Invalid group invite',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    if (invite.status == GroupInviteStatus.pending) {
      invite.status = GroupInviteStatus.declined;
    }
  }

  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) async {
    _requireAdmin(groupId);
    throw const AppException('User not found', code: 'GROUP_USER_NOT_FOUND');
  }

  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) async {
    _requireAdmin(groupId);
    final group = _requireGroup(groupId);
    final members = _members[groupId] ?? [];
    if (members.any(
      (member) =>
          member.userId == userId &&
          (member.status == GroupMemberStatus.active ||
              member.status == GroupMemberStatus.invited),
    )) {
      throw const AppException(
        'Member already invited',
        code: 'GROUP_MEMBER_ALREADY_INVITED',
      );
    }
    _members[groupId] = [
      ...members,
      SpendingGroupMember(
        id: _id('member'),
        groupId: groupId,
        userId: userId,
        role: GroupRole.member,
        status: GroupMemberStatus.invited,
        joinedAt: DateTime.now(),
        displayName: userId,
        username: userId,
      ),
    ];
    final token = _id('invite');
    _invites[token] = _MockGroupInvite(
      token: token,
      groupId: groupId,
      invitedBy: currentUserId,
      status: GroupInviteStatus.pending,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      invitedUserId: userId,
    );
    final notification = GroupNotification(
      id: _id('notification'),
      groupId: groupId,
      groupName: group.name,
      type: 'group_invite',
      isRead: false,
      createdAt: DateTime.now(),
      inviteToken: token,
    );
    _notifications[userId] = [notification, ...?_notifications[userId]];
  }

  Future<List<GroupTransaction>> fetchTransactions(String groupId) async {
    _requireGroup(groupId);
    final result =
        _recordsForGroup(groupId).map((record) => record.transaction).toList()
          ..sort(
            (left, right) =>
                right.transactionDate.compareTo(left.transactionDate),
          );
    return List.unmodifiable(result);
  }

  Future<GroupTransactionDetail> fetchTransactionDetail(
    String transactionId,
  ) async {
    final record = _requireTransaction(transactionId);
    _requireGroup(record.transaction.groupId);
    return record.detail;
  }

  Future<String> createTransaction(GroupTransactionDraft draft) async {
    _requireActiveMember(draft.groupId);
    final memberIds = _activeMembers(
      draft.groupId,
    ).map((member) => member.userId).toList();
    final now = DateTime.now();
    final id = _id('transaction');
    late final Map<String, int> shares;
    late final Map<String, int> paidAmounts;
    late final GroupSplitStatus splitStatus;
    if (draft.splitMode == GroupSplitMode.equal) {
      final result = _splitCalculator.calculate(
        totalAmount: draft.totalAmount,
        activeMemberIds: memberIds,
        splitMode: draft.splitMode,
        paymentMode: draft.paymentMode,
        payerAmounts: draft.payerAmounts,
      );
      shares = result.shares;
      paidAmounts = result.paidAmounts;
      splitStatus = GroupSplitStatus.posted;
    } else {
      _validatePayerDraft(draft, memberIds);
      shares = {for (final id in memberIds) id: 0};
      paidAmounts = draft.paymentMode == GroupPaymentMode.everyonePaid
          ? {for (final id in memberIds) id: 0}
          : {for (final id in memberIds) id: draft.payerAmounts[id] ?? 0};
      splitStatus = GroupSplitStatus.pendingMemberAmountInput;
    }

    final transaction = GroupTransaction(
      id: id,
      groupId: draft.groupId,
      createdBy: currentUserId,
      totalAmount: draft.totalAmount,
      categoryId: draft.categoryId,
      categoryName: draft.categoryName,
      caption: _blankToNull(draft.caption),
      note: _blankToNull(draft.note),
      imageUploadStatus: draft.imageFilePath == null
          ? GroupImageUploadStatus.pending
          : GroupImageUploadStatus.uploaded,
      imagePath: draft.imageFilePath,
      splitMode: draft.splitMode,
      paymentMode: draft.paymentMode,
      splitStatus: splitStatus,
      transactionDate: now,
      createdAt: now,
      updatedAt: now,
      creatorName: 'mock-user',
    );
    _transactions[id] = _MockTransactionRecord(
      transaction: transaction,
      payers: _payers(id, paidAmounts, now),
      shares: _shares(
        id,
        shares,
        now,
        submitted: draft.splitMode == GroupSplitMode.equal
            ? memberIds.toSet()
            : {},
      ),
      comments: [],
    );
    _recordActivity(
      draft.groupId,
      'transaction_created',
      metadata: {'transactionId': id},
    );
    _notifyActiveMembers(
      draft.groupId,
      splitStatus == GroupSplitStatus.pendingMemberAmountInput
          ? 'member_amount_required'
          : 'transaction_created',
      excludeCurrentUser: false,
      transactionId: id,
    );
    if (splitStatus == GroupSplitStatus.posted) {
      _refreshSettlements(draft.groupId);
    }
    return id;
  }

  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) async {
    final existing = _requireTransaction(transactionId);
    if (existing.transaction.createdBy != currentUserId) {
      throw const AppException('Forbidden', code: 'GROUP_CREATOR_ONLY');
    }
    final oldImage = existing.transaction.imagePath;
    _transactions.remove(transactionId);
    final newId = await createTransaction(draft);
    final replacement = _transactions.remove(newId)!;
    _transactions[transactionId] = _MockTransactionRecord(
      transaction: GroupTransaction(
        id: transactionId,
        groupId: replacement.transaction.groupId,
        createdBy: currentUserId,
        totalAmount: replacement.transaction.totalAmount,
        categoryId: replacement.transaction.categoryId,
        categoryName: replacement.transaction.categoryName,
        caption: replacement.transaction.caption,
        note: replacement.transaction.note,
        imagePath: replacement.transaction.imagePath ?? oldImage,
        imageUploadStatus: replacement.transaction.imageUploadStatus,
        splitMode: replacement.transaction.splitMode,
        paymentMode: replacement.transaction.paymentMode,
        splitStatus: replacement.transaction.splitStatus,
        transactionDate: existing.transaction.transactionDate,
        createdAt: existing.transaction.createdAt,
        updatedAt: DateTime.now(),
        creatorName: 'mock-user',
        hasCompletedSettlement: existing.transaction.hasCompletedSettlement,
      ),
      payers: replacement.payers
          .map(
            (payer) => GroupTransactionPayer(
              id: payer.id,
              groupTransactionId: transactionId,
              userId: payer.userId,
              paidAmount: payer.paidAmount,
              createdAt: payer.createdAt,
              updatedAt: payer.updatedAt,
              displayName: payer.displayName,
            ),
          )
          .toList(),
      shares: replacement.shares
          .map(
            (share) => GroupTransactionShare(
              id: share.id,
              groupTransactionId: transactionId,
              userId: share.userId,
              shareAmount: share.shareAmount,
              inputStatus: share.inputStatus,
              submittedAt: share.submittedAt,
              createdAt: share.createdAt,
              updatedAt: share.updatedAt,
              displayName: share.displayName,
            ),
          )
          .toList(),
      comments: existing.comments,
    );
    _refreshSettlements(draft.groupId);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final record = _requireTransaction(transactionId);
    if (record.transaction.createdBy != currentUserId) {
      throw const AppException('Forbidden', code: 'GROUP_CREATOR_ONLY');
    }
    _transactions.remove(transactionId);
    _refreshSettlements(record.transaction.groupId);
  }

  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  }) async {
    if (shareAmount < 0) {
      throw const AppException(
        'Share amount must be non-negative',
        code: 'GROUP_SHARE_NEGATIVE',
      );
    }
    final record = _requireTransaction(transactionId);
    _requireActiveMember(record.transaction.groupId);
    final index = record.shares.indexWhere(
      (share) => share.userId == currentUserId,
    );
    if (index == -1) {
      throw const AppException('Share not found', code: 'NOT_FOUND');
    }
    final now = DateTime.now();
    record.shares[index] = GroupTransactionShare(
      id: record.shares[index].id,
      groupTransactionId: transactionId,
      userId: currentUserId,
      shareAmount: shareAmount,
      inputStatus: GroupShareInputStatus.submitted,
      submittedAt: now,
      createdAt: record.shares[index].createdAt,
      updatedAt: now,
      displayName: record.shares[index].displayName,
    );
    final allSubmitted = record.shares.every(
      (share) => share.inputStatus == GroupShareInputStatus.submitted,
    );
    var status = GroupSplitStatus.pendingMemberAmountInput;
    if (allSubmitted) {
      final shareMap = {
        for (final share in record.shares) share.userId: share.shareAmount,
      };
      try {
        final result = _splitCalculator.calculate(
          totalAmount: record.transaction.totalAmount,
          activeMemberIds: record.shares.map((share) => share.userId).toList(),
          splitMode: GroupSplitMode.unequal,
          paymentMode: record.transaction.paymentMode,
          unequalShares: shareMap,
          submittedMemberIds: shareMap.keys.toSet(),
          payerAmounts: {
            for (final payer in record.payers)
              if (payer.paidAmount > 0) payer.userId: payer.paidAmount,
          },
        );
        status = GroupSplitStatus.posted;
        record.payers
          ..clear()
          ..addAll(_payers(transactionId, result.paidAmounts, now));
      } on GroupSplitException catch (error) {
        if (error.error == GroupSplitError.shareTotalMismatch) {
          status = GroupSplitStatus.amountMismatch;
        } else {
          rethrow;
        }
      }
    }
    record.transaction = _copyTransaction(record.transaction, status: status);
    if (status == GroupSplitStatus.posted) {
      _refreshSettlements(record.transaction.groupId);
      _recordActivity(
        record.transaction.groupId,
        'transaction_posted',
        metadata: {'transactionId': transactionId},
      );
      _notifyActiveMembers(
        record.transaction.groupId,
        'transaction_posted',
        excludeCurrentUser: false,
        transactionId: transactionId,
      );
    }
  }

  Future<GroupSettlementOverview> fetchSettlementOverview(
    String groupId,
  ) async {
    _requireGroup(groupId);
    final names = {
      for (final member in _members[groupId] ?? const <SpendingGroupMember>[])
        member.userId: member.resolvedName,
    };
    final records = _recordsForGroup(groupId);
    final totals = <String, ({int shares, int paid})>{};
    for (final record in records.where(
      (item) => item.transaction.splitStatus == GroupSplitStatus.posted,
    )) {
      for (final share in record.shares) {
        final current = totals[share.userId] ?? (shares: 0, paid: 0);
        totals[share.userId] = (
          shares: current.shares + share.shareAmount,
          paid: current.paid,
        );
      }
      for (final payer in record.payers) {
        final current = totals[payer.userId] ?? (shares: 0, paid: 0);
        totals[payer.userId] = (
          shares: current.shares,
          paid: current.paid + payer.paidAmount,
        );
      }
    }
    final balances = totals.entries
        .map(
          (entry) => GroupBalance(
            groupId: groupId,
            userId: entry.key,
            totalShareAmount: entry.value.shares,
            totalPaidAmount: entry.value.paid,
            balance: _groupBalances(groupId)[entry.key] ?? 0,
            displayName: names[entry.key],
          ),
        )
        .toList();
    return GroupSettlementOverview(
      balances: List.unmodifiable(balances),
      suggestions: List.unmodifiable(_settlements[groupId] ?? const []),
    );
  }

  Future<GroupStatsOverview> fetchStats(String groupId) async {
    final detail = await fetchGroupDetail(groupId);
    final transactions = await fetchTransactions(groupId);
    final settlements = await fetchSettlementOverview(groupId);
    return GroupStatsOverview(
      totalSpent: transactions
          .where(
            (transaction) => transaction.splitStatus == GroupSplitStatus.posted,
          )
          .fold<int>(0, (sum, transaction) => sum + transaction.totalAmount),
      transactionCount: transactions.length,
      pendingTransactionCount: transactions
          .where(
            (transaction) =>
                transaction.splitStatus != GroupSplitStatus.posted &&
                transaction.splitStatus != GroupSplitStatus.cancelled,
          )
          .length,
      pendingSettlementCount: settlements.suggestions
          .where((item) => item.status != GroupSettlementStatus.completed)
          .length,
      memberCount: detail.activeMembers.length,
      currentUserBalance: settlements.balances
          .where((item) => item.userId == currentUserId)
          .fold<int>(0, (sum, item) => sum + item.balance),
    );
  }

  Future<List<GroupNotification>> fetchNotifications() async {
    return List.unmodifiable(_notifications[currentUserId] ?? const []);
  }

  Future<void> markNotificationRead(String notificationId) async {
    final notifications = _notifications[currentUserId] ?? [];
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;
    final item = notifications[index];
    notifications[index] = GroupNotification(
      id: item.id,
      groupId: item.groupId,
      groupName: item.groupName,
      type: item.type,
      isRead: true,
      createdAt: item.createdAt,
      groupTransactionId: item.groupTransactionId,
      inviteToken: item.inviteToken,
    );
  }

  Future<List<GroupActivity>> fetchActivities(String groupId) async {
    _requireGroup(groupId);
    final result = List<GroupActivity>.from(_activities[groupId] ?? const []);
    result.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(result);
  }

  Future<void> markSettlementPaid(String settlementId) async {
    final match = _findSettlement(settlementId);
    if (match.item.fromUserId != currentUserId ||
        match.item.status != GroupSettlementStatus.pending) {
      throw const AppException('Forbidden', code: 'GROUP_SETTLEMENT_FORBIDDEN');
    }
    match.list[match.index] = _copySettlement(
      match.item,
      status: GroupSettlementStatus.payerMarkedPaid,
      payerMarkedPaidAt: DateTime.now(),
    );
  }

  Future<void> confirmSettlementReceived(String settlementId) async {
    final match = _findSettlement(settlementId);
    if (match.item.toUserId != currentUserId ||
        match.item.status != GroupSettlementStatus.payerMarkedPaid) {
      throw const AppException('Forbidden', code: 'GROUP_SETTLEMENT_FORBIDDEN');
    }
    match.list[match.index] = _copySettlement(
      match.item,
      status: GroupSettlementStatus.completed,
      receiverConfirmedAt: DateTime.now(),
    );
    _refreshSettlements(match.item.groupId);
  }

  Future<void> disputeSettlement(String settlementId) async {
    final match = _findSettlement(settlementId);
    if (match.item.toUserId != currentUserId ||
        match.item.status != GroupSettlementStatus.payerMarkedPaid) {
      throw const AppException('Forbidden', code: 'GROUP_SETTLEMENT_FORBIDDEN');
    }
    match.list[match.index] = _copySettlement(
      match.item,
      status: GroupSettlementStatus.disputed,
    );
  }

  Future<void> resetDisputedSettlement(String settlementId) async {
    final match = _findSettlement(settlementId);
    _requireAdmin(match.item.groupId);
    if (match.item.status != GroupSettlementStatus.disputed) {
      throw const AppException('Forbidden', code: 'GROUP_SETTLEMENT_FORBIDDEN');
    }
    match.list[match.index] = _copySettlement(
      match.item,
      status: GroupSettlementStatus.pending,
    );
  }

  Future<void> leaveGroup(String groupId) async {
    final detail = await fetchGroupDetail(groupId);
    final balance = _groupBalances(groupId)[currentUserId] ?? 0;
    final unresolved =
        _settlements[groupId]?.any(
          (item) =>
              (item.fromUserId == currentUserId ||
                  item.toUserId == currentUserId) &&
              item.status != GroupSettlementStatus.completed,
        ) ??
        false;
    if (balance != 0 || unresolved) {
      _recordActivity(groupId, 'leave_blocked_unresolved');
      _notifyActiveMembers(
        groupId,
        'member_leave_blocked_warning',
        excludeCurrentUser: true,
      );
      throw const AppException(
        'Unresolved group balance',
        code: 'GROUP_LEAVE_UNRESOLVED',
      );
    }
    if (detail.currentUserRole == GroupRole.owner &&
        detail.activeMembers
            .where(
              (member) =>
                  member.userId != currentUserId &&
                  member.role == GroupRole.owner,
            )
            .isEmpty) {
      throw const AppException(
        'Owner transfer required',
        code: 'GROUP_OWNER_TRANSFER_REQUIRED',
      );
    }
    final memberIndex = _members[groupId]!.indexWhere(
      (member) => member.userId == currentUserId,
    );
    final member = _members[groupId]![memberIndex];
    _members[groupId]![memberIndex] = SpendingGroupMember(
      id: member.id,
      groupId: member.groupId,
      userId: member.userId,
      role: member.role,
      status: GroupMemberStatus.left,
      joinedAt: member.joinedAt,
      leftAt: DateTime.now(),
      displayName: member.displayName,
      username: member.username,
      avatarPath: member.avatarPath,
    );
    _recordActivity(groupId, 'member_left');
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) async {
    final detail = await fetchGroupDetail(groupId);
    if (detail.currentUserRole != GroupRole.owner) {
      throw const AppException('Owner required', code: 'GROUP_OWNER_REQUIRED');
    }
    if (newOwnerUserId == currentUserId) {
      throw const AppException(
        'New owner required',
        code: 'GROUP_OWNER_TRANSFER_TARGET_REQUIRED',
      );
    }
    final members = _members[groupId]!;
    final currentIndex = members.indexWhere(
      (member) =>
          member.userId == currentUserId &&
          member.status == GroupMemberStatus.active,
    );
    final targetIndex = members.indexWhere(
      (member) =>
          member.userId == newOwnerUserId &&
          member.status == GroupMemberStatus.active,
    );
    if (currentIndex == -1 || targetIndex == -1) {
      throw const AppException('Group member required', code: 'NOT_FOUND');
    }
    members[currentIndex] = _copyMember(
      members[currentIndex],
      GroupRole.member,
    );
    members[targetIndex] = _copyMember(members[targetIndex], GroupRole.owner);
    _recordActivity(
      groupId,
      'owner_transferred',
      metadata: {'new_owner_user_id': newOwnerUserId},
    );
    _notifyActiveMembers(
      groupId,
      'owner_transferred',
      excludeCurrentUser: true,
    );
  }

  Future<void> addComment({
    required String transactionId,
    required String content,
  }) async {
    final record = _requireTransaction(transactionId);
    _requireActiveMember(record.transaction.groupId);
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        'Comment required',
        code: 'GROUP_COMMENT_REQUIRED',
      );
    }
    final now = DateTime.now();
    record.comments.add(
      GroupTransactionComment(
        id: _id('comment'),
        groupTransactionId: transactionId,
        userId: currentUserId,
        content: trimmed,
        createdAt: now,
        updatedAt: now,
        displayName: 'mock-user',
      ),
    );
  }

  Future<void> updateComment({
    required String commentId,
    required String transactionId,
    required String content,
  }) async {
    final record = _requireTransaction(transactionId);
    final index = record.comments.indexWhere((item) => item.id == commentId);
    if (index == -1) {
      throw const AppException('Comment not found', code: 'NOT_FOUND');
    }
    final existing = record.comments[index];
    if (existing.userId != currentUserId) {
      throw const AppException(
        'Comment owner required',
        code: 'GROUP_COMMENT_OWNER_REQUIRED',
      );
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        'Comment required',
        code: 'GROUP_COMMENT_REQUIRED',
      );
    }
    record.comments[index] = GroupTransactionComment(
      id: existing.id,
      groupTransactionId: existing.groupTransactionId,
      userId: existing.userId,
      content: trimmed,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      displayName: existing.displayName,
      avatarPath: existing.avatarPath,
    );
  }

  Future<void> deleteComment({
    required String commentId,
    required String transactionId,
  }) async {
    final record = _requireTransaction(transactionId);
    final index = record.comments.indexWhere((item) => item.id == commentId);
    if (index == -1) {
      throw const AppException('Comment not found', code: 'NOT_FOUND');
    }
    if (record.comments[index].userId != currentUserId) {
      throw const AppException(
        'Comment owner required',
        code: 'GROUP_COMMENT_OWNER_REQUIRED',
      );
    }
    record.comments.removeAt(index);
  }

  void _validatePayerDraft(
    GroupTransactionDraft draft,
    List<String> memberIds,
  ) {
    if (draft.paymentMode == GroupPaymentMode.everyonePaid) {
      return;
    }
    _splitCalculator.calculate(
      totalAmount: draft.totalAmount,
      activeMemberIds: memberIds,
      splitMode: GroupSplitMode.equal,
      paymentMode: draft.paymentMode,
      payerAmounts: draft.payerAmounts,
    );
  }

  void _refreshSettlements(String groupId) {
    final retained =
        _settlements[groupId]
            ?.where(
              (item) =>
                  item.status == GroupSettlementStatus.completed ||
                  item.status == GroupSettlementStatus.payerMarkedPaid ||
                  item.status == GroupSettlementStatus.disputed,
            )
            .toList() ??
        [];
    final balances = _groupBalances(groupId);
    for (final item in retained.where(
      (entry) => entry.status == GroupSettlementStatus.payerMarkedPaid,
    )) {
      balances[item.fromUserId] =
          (balances[item.fromUserId] ?? 0) - item.amount;
      balances[item.toUserId] = (balances[item.toUserId] ?? 0) + item.amount;
    }
    final names = {
      for (final member in _members[groupId] ?? const <SpendingGroupMember>[])
        member.userId: member.resolvedName,
    };
    final now = DateTime.now();
    retained.addAll(
      _settlementCalculator
          .calculate(balances)
          .map(
            (item) => GroupSettlementSuggestion(
              id: _id('settlement'),
              groupId: groupId,
              fromUserId: item.fromUserId,
              toUserId: item.toUserId,
              amount: item.amount,
              status: GroupSettlementStatus.pending,
              createdAt: now,
              updatedAt: now,
              fromDisplayName: names[item.fromUserId],
              toDisplayName: names[item.toUserId],
            ),
          ),
    );
    _settlements[groupId] = retained;
  }

  void _recordActivity(
    String groupId,
    String type, {
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    final activity = GroupActivity(
      id: _id('activity'),
      groupId: groupId,
      actorUserId: currentUserId,
      actorName: _displayName(groupId, currentUserId),
      type: type,
      metadata: metadata,
      createdAt: now,
    );
    _activities[groupId] = [activity, ...?_activities[groupId]];
  }

  void _notifyActiveMembers(
    String groupId,
    String type, {
    bool excludeCurrentUser = false,
    String? transactionId,
  }) {
    final group = _groups[groupId];
    if (group == null) return;
    for (final member in _activeMembers(groupId)) {
      if (excludeCurrentUser && member.userId == currentUserId) continue;
      final notification = GroupNotification(
        id: _id('notification'),
        groupId: groupId,
        groupName: group.name,
        groupTransactionId: transactionId,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      _notifications[member.userId] = [
        notification,
        ...?_notifications[member.userId],
      ];
    }
  }

  String? _displayName(String groupId, String userId) {
    final members = _members[groupId] ?? const <SpendingGroupMember>[];
    for (final member in members) {
      if (member.userId == userId) return member.resolvedName;
    }
    return userId;
  }

  Map<String, int> _groupBalances(String groupId) {
    final balances = <String, int>{};
    for (final record in _recordsForGroup(groupId).where(
      (item) => item.transaction.splitStatus == GroupSplitStatus.posted,
    )) {
      for (final share in record.shares) {
        balances[share.userId] =
            (balances[share.userId] ?? 0) + share.shareAmount;
      }
      for (final payer in record.payers) {
        balances[payer.userId] =
            (balances[payer.userId] ?? 0) - payer.paidAmount;
      }
    }
    for (final settlement
        in _settlements[groupId]?.where(
              (item) => item.status == GroupSettlementStatus.completed,
            ) ??
            const <GroupSettlementSuggestion>[]) {
      balances[settlement.fromUserId] =
          (balances[settlement.fromUserId] ?? 0) - settlement.amount;
      balances[settlement.toUserId] =
          (balances[settlement.toUserId] ?? 0) + settlement.amount;
    }
    return balances;
  }

  List<GroupTransactionPayer> _payers(
    String transactionId,
    Map<String, int> amounts,
    DateTime now,
  ) {
    return amounts.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => GroupTransactionPayer(
            id: _id('payer'),
            groupTransactionId: transactionId,
            userId: entry.key,
            paidAmount: entry.value,
            createdAt: now,
            updatedAt: now,
            displayName: entry.key == currentUserId ? 'mock-user' : null,
          ),
        )
        .toList();
  }

  List<GroupTransactionShare> _shares(
    String transactionId,
    Map<String, int> amounts,
    DateTime now, {
    required Set<String> submitted,
  }) {
    return amounts.entries
        .map(
          (entry) => GroupTransactionShare(
            id: _id('share'),
            groupTransactionId: transactionId,
            userId: entry.key,
            shareAmount: entry.value,
            inputStatus: submitted.contains(entry.key)
                ? GroupShareInputStatus.submitted
                : GroupShareInputStatus.pending,
            submittedAt: submitted.contains(entry.key) ? now : null,
            createdAt: now,
            updatedAt: now,
            displayName: entry.key == currentUserId ? 'mock-user' : null,
          ),
        )
        .toList();
  }

  SpendingGroup _requireGroup(String groupId) {
    final group = _groups[groupId];
    if (group == null) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    final isMember =
        _members[groupId]?.any(
          (member) =>
              member.userId == currentUserId &&
              member.status == GroupMemberStatus.active,
        ) ??
        false;
    if (!isMember) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    return group;
  }

  void _requireActiveMember(String groupId) {
    _requireGroup(groupId);
  }

  void _requireAdmin(String groupId) {
    _requireGroup(groupId);
    final member = _members[groupId]!.firstWhere(
      (item) =>
          item.userId == currentUserId &&
          item.status == GroupMemberStatus.active,
    );
    if (member.role != GroupRole.owner && member.role != GroupRole.admin) {
      throw const AppException('Forbidden', code: 'GROUP_ADMIN_REQUIRED');
    }
  }

  _MockTransactionRecord _requireTransaction(String transactionId) {
    final record = _transactions[transactionId];
    if (record == null) {
      throw const AppException('Transaction not found', code: 'NOT_FOUND');
    }
    return record;
  }

  List<SpendingGroupMember> _activeMembers(String groupId) =>
      (_members[groupId] ?? const [])
          .where((member) => member.status == GroupMemberStatus.active)
          .toList();

  List<_MockTransactionRecord> _recordsForGroup(String groupId) => _transactions
      .values
      .where((record) => record.transaction.groupId == groupId)
      .toList();

  SpendingGroupMember _copyMember(SpendingGroupMember value, GroupRole role) {
    return SpendingGroupMember(
      id: value.id,
      groupId: value.groupId,
      userId: value.userId,
      role: role,
      status: value.status,
      joinedAt: value.joinedAt,
      leftAt: value.leftAt,
      displayName: value.displayName,
      username: value.username,
      avatarPath: value.avatarPath,
    );
  }

  _SettlementMatch _findSettlement(String settlementId) {
    for (final list in _settlements.values) {
      final index = list.indexWhere((item) => item.id == settlementId);
      if (index != -1) {
        return _SettlementMatch(list, index, list[index]);
      }
    }
    throw const AppException('Settlement not found', code: 'NOT_FOUND');
  }

  GroupTransaction _copyTransaction(
    GroupTransaction value, {
    required GroupSplitStatus status,
  }) {
    return GroupTransaction(
      id: value.id,
      groupId: value.groupId,
      createdBy: value.createdBy,
      totalAmount: value.totalAmount,
      categoryId: value.categoryId,
      categoryName: value.categoryName,
      caption: value.caption,
      note: value.note,
      imagePath: value.imagePath,
      imageUploadStatus: value.imageUploadStatus,
      splitMode: value.splitMode,
      paymentMode: value.paymentMode,
      splitStatus: status,
      transactionDate: value.transactionDate,
      createdAt: value.createdAt,
      updatedAt: DateTime.now(),
      creatorName: value.creatorName,
      hasCompletedSettlement: value.hasCompletedSettlement,
    );
  }

  GroupSettlementSuggestion _copySettlement(
    GroupSettlementSuggestion value, {
    required GroupSettlementStatus status,
    DateTime? payerMarkedPaidAt,
    DateTime? receiverConfirmedAt,
  }) {
    return GroupSettlementSuggestion(
      id: value.id,
      groupId: value.groupId,
      fromUserId: value.fromUserId,
      toUserId: value.toUserId,
      amount: value.amount,
      status: status,
      payerMarkedPaidAt: payerMarkedPaidAt ?? value.payerMarkedPaidAt,
      receiverConfirmedAt: receiverConfirmedAt ?? value.receiverConfirmedAt,
      createdAt: value.createdAt,
      updatedAt: DateTime.now(),
      fromDisplayName: value.fromDisplayName,
      toDisplayName: value.toDisplayName,
    );
  }

  static String? _blankToNull(String? value) =>
      value?.trim().isEmpty == true ? null : value?.trim();

  static String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
}

class _MockTransactionRecord {
  _MockTransactionRecord({
    required this.transaction,
    required this.payers,
    required this.shares,
    required this.comments,
  });

  GroupTransaction transaction;
  final List<GroupTransactionPayer> payers;
  final List<GroupTransactionShare> shares;
  final List<GroupTransactionComment> comments;

  GroupTransactionDetail get detail => GroupTransactionDetail(
    transaction: transaction,
    payers: List.unmodifiable(payers),
    shares: List.unmodifiable(shares),
    comments: List.unmodifiable(comments),
  );
}

class _SettlementMatch {
  const _SettlementMatch(this.list, this.index, this.item);

  final List<GroupSettlementSuggestion> list;
  final int index;
  final GroupSettlementSuggestion item;
}

class _MockGroupInvite {
  _MockGroupInvite({
    required this.token,
    required this.groupId,
    required this.invitedBy,
    required this.status,
    required this.expiresAt,
    this.invitedUserId,
  });

  final String token;
  final String groupId;
  final String invitedBy;
  final String? invitedUserId;
  GroupInviteStatus status;
  final DateTime expiresAt;
}
