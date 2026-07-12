import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_invite.dart';
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
  static final Map<String, _MockGroupInviteLink> _inviteLinks = {};
  static final Map<String, _MockDirectGroupInvite> _directInvites = {};
  static var _sequence = 0;

  static void resetForTesting() {
    _groups.clear();
    _members.clear();
    _transactions.clear();
    _settlements.clear();
    _inviteLinks.clear();
    _directInvites.clear();
    _sequence = 0;
  }

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
    for (final invite in _inviteLinks.values) {
      if (invite.groupId == groupId &&
          invite.status == GroupInviteStatus.active) {
        invite.status = GroupInviteStatus.revoked;
      }
    }
    final token = _id('invite');
    _inviteLinks[token] = _MockGroupInviteLink(
      token: token,
      groupId: groupId,
      invitedBy: currentUserId,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    return AppConstants.groupInviteLink(token);
  }

  Future<GroupInvitePreview> fetchInvitePreview(String token) async {
    final invite = _inviteLinks[token.trim()];
    if (invite == null) {
      return const GroupInvitePreview(status: GroupInviteStatus.invalid);
    }
    if (invite.status == GroupInviteStatus.active &&
        !invite.expiresAt.isAfter(DateTime.now())) {
      invite.status = GroupInviteStatus.expired;
    }
    final group = _groups[invite.groupId];
    if (group == null) {
      return const GroupInvitePreview(status: GroupInviteStatus.invalid);
    }
    final isMember = (_members[invite.groupId] ?? const []).any(
      (member) =>
          member.userId == currentUserId &&
          member.status == GroupMemberStatus.active,
    );
    return GroupInvitePreview(
      status: isMember ? GroupInviteStatus.alreadyMember : invite.status,
      groupId: group.id,
      groupName: group.name,
      groupAvatarPath: group.avatarPath,
      inviterName: invite.invitedBy == currentUserId
          ? 'mock-user'
          : invite.invitedBy,
      expiresAt: invite.expiresAt,
    );
  }

  Future<GroupInviteAcceptResult> acceptInvite(String token) async {
    final preview = await fetchInvitePreview(token);
    final groupId = preview.groupId;
    if (groupId == null) {
      throw const AppException(
        'Invite not found',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    if (preview.status == GroupInviteStatus.alreadyMember) {
      return GroupInviteAcceptResult(
        status: GroupInviteStatus.alreadyMember,
        groupId: groupId,
      );
    }
    if (!preview.canAccept) {
      throw AppException(
        'Invite cannot be accepted',
        code: _inviteErrorCode(preview.status),
      );
    }
    final members = _members[groupId] ?? const <SpendingGroupMember>[];
    final existingIndex = members.indexWhere(
      (member) => member.userId == currentUserId,
    );
    final activeMember = SpendingGroupMember(
      id: existingIndex == -1 ? _id('member') : members[existingIndex].id,
      groupId: groupId,
      userId: currentUserId,
      role: GroupRole.member,
      status: GroupMemberStatus.active,
      joinedAt: DateTime.now(),
      displayName: currentUserId == 'mock-user-id'
          ? 'mock-user'
          : currentUserId,
      username: currentUserId == 'mock-user-id' ? 'mock-user' : currentUserId,
    );
    _members[groupId] = [
      for (var index = 0; index < members.length; index++)
        if (index == existingIndex) activeMember else members[index],
      if (existingIndex == -1) activeMember,
    ];
    return GroupInviteAcceptResult(
      status: GroupInviteStatus.accepted,
      groupId: groupId,
    );
  }

  Future<void> revokeInviteLink(String token) async {
    final invite = _inviteLinks[token.trim()];
    if (invite == null) {
      throw const AppException(
        'Invite not found',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    _requireAdmin(invite.groupId);
    if (invite.status == GroupInviteStatus.active) {
      invite.status = GroupInviteStatus.revoked;
    }
  }

  Future<List<GroupDirectInvite>> fetchDirectInvites() async {
    for (final invite in _directInvites.values) {
      _expireDirectInviteIfNeeded(invite);
      if (invite.status == GroupDirectInviteStatus.pending &&
          _isActiveMember(invite.groupId, invite.invitedUserId)) {
        invite.status = GroupDirectInviteStatus.accepted;
      }
    }
    final invites =
        _directInvites.values
            .where((invite) => invite.invitedUserId == currentUserId)
            .map((invite) {
              final group = _groups[invite.groupId];
              if (group == null) return null;
              return GroupDirectInvite(
                id: invite.id,
                groupId: group.id,
                groupName: group.name,
                groupAvatarPath: group.avatarPath,
                inviterName: invite.invitedBy,
                status: invite.status,
                createdAt: invite.createdAt,
                expiresAt: invite.expiresAt,
              );
            })
            .whereType<GroupDirectInvite>()
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(invites);
  }

  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId) async {
    final invite = _directInvites[inviteId];
    if (invite == null || invite.invitedUserId != currentUserId) {
      throw const AppException(
        'Invite not found',
        code: 'GROUP_DIRECT_INVITE_INVALID',
      );
    }
    _expireDirectInviteIfNeeded(invite);
    final group = _groups[invite.groupId];
    if (group == null || group.status != GroupStatus.active) {
      throw const AppException(
        'Invite cannot be accepted',
        code: 'GROUP_DIRECT_INVITE_INVALID',
      );
    }
    if (_isActiveMember(invite.groupId, currentUserId)) {
      if (invite.status == GroupDirectInviteStatus.pending) {
        invite.status = GroupDirectInviteStatus.accepted;
      }
      return GroupInviteAcceptResult(
        status: GroupInviteStatus.alreadyMember,
        groupId: invite.groupId,
      );
    }
    if (invite.status != GroupDirectInviteStatus.pending) {
      throw AppException(
        'Invite cannot be accepted',
        code: _directInviteErrorCode(invite.status),
      );
    }
    invite.status = GroupDirectInviteStatus.accepted;
    _setMemberStatus(
      groupId: invite.groupId,
      userId: currentUserId,
      status: GroupMemberStatus.active,
    );
    return GroupInviteAcceptResult(
      status: GroupInviteStatus.accepted,
      groupId: invite.groupId,
    );
  }

  Future<void> declineDirectInvite(String inviteId) async {
    final invite = _directInvites[inviteId];
    if (invite == null || invite.invitedUserId != currentUserId) {
      throw const AppException(
        'Invite not found',
        code: 'GROUP_DIRECT_INVITE_INVALID',
      );
    }
    _expireDirectInviteIfNeeded(invite);
    if (invite.status == GroupDirectInviteStatus.declined ||
        invite.status == GroupDirectInviteStatus.accepted) {
      return;
    }
    if (invite.status != GroupDirectInviteStatus.pending) {
      throw AppException(
        'Invite cannot be declined',
        code: _directInviteErrorCode(invite.status),
      );
    }
    invite.status = GroupDirectInviteStatus.declined;
    _setMemberStatus(
      groupId: invite.groupId,
      userId: currentUserId,
      status: GroupMemberStatus.declined,
    );
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
    _setMemberStatus(
      groupId: groupId,
      userId: userId,
      status: GroupMemberStatus.invited,
    );
    final now = DateTime.now();
    final inviteId = _id('direct-invite');
    _directInvites[inviteId] = _MockDirectGroupInvite(
      id: inviteId,
      groupId: groupId,
      invitedUserId: userId,
      invitedBy: currentUserId,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
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
                  item.status == GroupSettlementStatus.payerMarkedPaid,
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

  bool _isActiveMember(String groupId, String userId) =>
      (_members[groupId] ?? const []).any(
        (member) =>
            member.userId == userId &&
            member.status == GroupMemberStatus.active,
      );

  void _setMemberStatus({
    required String groupId,
    required String userId,
    required GroupMemberStatus status,
  }) {
    final members = _members[groupId] ?? <SpendingGroupMember>[];
    final index = members.indexWhere((member) => member.userId == userId);
    final now = DateTime.now();
    final member = index == -1
        ? SpendingGroupMember(
            id: _id('member'),
            groupId: groupId,
            userId: userId,
            role: GroupRole.member,
            status: status,
            joinedAt: now,
            leftAt: status == GroupMemberStatus.left ? now : null,
            displayName: userId,
            username: userId,
          )
        : SpendingGroupMember(
            id: members[index].id,
            groupId: groupId,
            userId: userId,
            role: members[index].role,
            status: status,
            joinedAt: now,
            leftAt: status == GroupMemberStatus.left ? now : null,
            displayName: members[index].displayName,
            username: members[index].username,
            avatarPath: members[index].avatarPath,
          );
    _members[groupId] = [
      for (var position = 0; position < members.length; position++)
        if (position == index) member else members[position],
      if (index == -1) member,
    ];
  }

  void _expireDirectInviteIfNeeded(_MockDirectGroupInvite invite) {
    if (invite.status != GroupDirectInviteStatus.pending ||
        invite.expiresAt.isAfter(DateTime.now())) {
      return;
    }
    invite.status = GroupDirectInviteStatus.expired;
    _setMemberStatus(
      groupId: invite.groupId,
      userId: invite.invitedUserId,
      status: GroupMemberStatus.declined,
    );
  }

  List<_MockTransactionRecord> _recordsForGroup(String groupId) => _transactions
      .values
      .where((record) => record.transaction.groupId == groupId)
      .toList();

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

  static String _inviteErrorCode(GroupInviteStatus status) => switch (status) {
    GroupInviteStatus.expired => 'GROUP_INVITE_EXPIRED',
    GroupInviteStatus.revoked => 'GROUP_INVITE_REVOKED',
    GroupInviteStatus.used => 'GROUP_INVITE_USED',
    GroupInviteStatus.invalid => 'GROUP_INVITE_INVALID',
    GroupInviteStatus.alreadyMember ||
    GroupInviteStatus.active ||
    GroupInviteStatus.accepted => 'GROUP_INVITE_INVALID',
  };

  static String _directInviteErrorCode(GroupDirectInviteStatus status) =>
      switch (status) {
        GroupDirectInviteStatus.expired => 'GROUP_DIRECT_INVITE_EXPIRED',
        GroupDirectInviteStatus.declined => 'GROUP_DIRECT_INVITE_DECLINED',
        GroupDirectInviteStatus.revoked => 'GROUP_DIRECT_INVITE_REVOKED',
        GroupDirectInviteStatus.invalid ||
        GroupDirectInviteStatus.pending ||
        GroupDirectInviteStatus.accepted ||
        GroupDirectInviteStatus.alreadyMember => 'GROUP_DIRECT_INVITE_INVALID',
      };

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

class _MockGroupInviteLink {
  _MockGroupInviteLink({
    required this.token,
    required this.groupId,
    required this.invitedBy,
    required this.expiresAt,
  });

  final String token;
  final String groupId;
  final String invitedBy;
  final DateTime expiresAt;
  GroupInviteStatus status = GroupInviteStatus.active;
}

class _MockDirectGroupInvite {
  _MockDirectGroupInvite({
    required this.id,
    required this.groupId,
    required this.invitedUserId,
    required this.invitedBy,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String groupId;
  final String invitedUserId;
  final String invitedBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  GroupDirectInviteStatus status = GroupDirectInviteStatus.pending;
}

class _SettlementMatch {
  const _SettlementMatch(this.list, this.index, this.item);

  final List<GroupSettlementSuggestion> list;
  final int index;
  final GroupSettlementSuggestion item;
}
