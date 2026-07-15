import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/services/group_split_calculator.dart';
import '../../domain/services/settlement_calculator.dart';

class GroupMockDataSource {
  GroupMockDataSource({required this.currentUserId});

  static const _demoUserId = 'mock-user-id';

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
  static final Map<String, Map<String, Set<String>>> _reactions = {};
  static final Map<String, List<GroupActivity>> _activities = {};
  static final Map<String, List<GroupNotification>> _notifications = {};
  static final Map<String, GroupNotificationPreference>
  _notificationPreferences = {};
  static final Map<String, GroupBudget> _budgets = {};
  static final Map<String, GroupPublicProfile> _publicProfiles = {};
  static final Map<String, GroupRecurringTransaction> _recurringTransactions =
      {};
  static var _sequence = 0;

  static void resetForTesting() {
    _groups.clear();
    _members.clear();
    _transactions.clear();
    _settlements.clear();
    _inviteLinks.clear();
    _directInvites.clear();
    _reactions.clear();
    _activities.clear();
    _notifications.clear();
    _sequence = 0;
  }

  Future<List<SpendingGroup>> fetchGroups() async {
    _seedDemoGroupsIfNeeded();
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
            memberAvatarPaths: _activeMembers(group.id)
                .map((member) => member.avatarPath)
                .take(5)
                .toList(growable: false),
            transactionCount: groupTransactions
                .where(
                  (record) =>
                      record.transaction.splitStatus == GroupSplitStatus.posted,
                )
                .length,
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

  void _seedDemoGroupsIfNeeded() {
    if (currentUserId != _demoUserId || _groups.isNotEmpty) return;

    final now = DateTime.now();
    final groups = [
      _DemoGroupSeed(
        id: 'mock-group-dalat',
        name: 'Đà Lạt 6/2025',
        memberCount: 5,
        transactionCount: 14,
        colorName: 'travel',
        avatarPath: 'asset://assets/demo_transactions/transport.png',
        createdAt: now.subtract(const Duration(days: 3)),
        balanceMode: _DemoBalanceMode.receive,
      ),
      _DemoGroupSeed(
        id: 'mock-group-home-q3',
        name: 'Nhà chung Q3',
        memberCount: 3,
        transactionCount: 28,
        colorName: 'home',
        avatarPath: 'asset://assets/demo_transactions/market.png',
        createdAt: now.subtract(const Duration(days: 7)),
        balanceMode: _DemoBalanceMode.pay,
      ),
      _DemoGroupSeed(
        id: 'mock-group-cafe-weekend',
        name: 'Cafe cuối tuần',
        memberCount: 4,
        transactionCount: 6,
        colorName: 'cafe',
        avatarPath: 'asset://assets/demo_transactions/cafe.png',
        createdAt: now.subtract(const Duration(days: 12)),
        balanceMode: _DemoBalanceMode.settled,
      ),
    ];

    for (final seed in groups) {
      _groups[seed.id] = SpendingGroup(
        id: seed.id,
        name: seed.name,
        description: seed.colorName,
        type: seed.colorName,
        avatarPath: seed.avatarPath,
        createdBy: currentUserId,
        status: GroupStatus.active,
        createdAt: seed.createdAt,
        updatedAt: seed.createdAt.add(const Duration(hours: 3)),
      );
      _members[seed.id] = [
        _demoMember(
          seed.id,
          currentUserId,
          'Minh Anh',
          GroupRole.owner,
          now,
          'asset://assets/demo_avatars/minh-anh.png',
        ),
        for (var index = 1; index < seed.memberCount; index++)
          _demoMember(
            seed.id,
            'mock-friend-$index',
            _demoMemberName(index),
            GroupRole.member,
            now.subtract(Duration(days: index)),
            _demoMemberAvatar(index),
          ),
      ];
      _seedDemoTransactions(seed, now);
      _refreshSettlements(seed.id);
    }
  }

  SpendingGroupMember _demoMember(
    String groupId,
    String userId,
    String displayName,
    GroupRole role,
    DateTime joinedAt,
    String avatarPath,
  ) {
    return SpendingGroupMember(
      id: '$groupId-member-$userId',
      groupId: groupId,
      userId: userId,
      role: role,
      status: GroupMemberStatus.active,
      joinedAt: joinedAt,
      displayName: displayName,
      username: userId,
      avatarPath: avatarPath,
    );
  }

  String _demoMemberAvatar(int index) {
    const avatars = [
      'asset://assets/demo_avatars/hoang-nam.png',
      'asset://assets/demo_avatars/bao-chau.png',
      'asset://assets/demo_avatars/linh.png',
      'asset://assets/demo_avatars/khoa.png',
      'asset://assets/demo_avatars/minh-anh.png',
    ];
    return avatars[(index - 1) % avatars.length];
  }

  String _demoMemberName(int index) {
    const names = ['Hoàng Nam', 'Bảo Châu', 'Linh', 'Khoa', 'Minh Anh'];
    return names[(index - 1) % names.length];
  }

  void _seedDemoTransactions(_DemoGroupSeed seed, DateTime now) {
    switch (seed.balanceMode) {
      case _DemoBalanceMode.receive:
        _addDemoTransaction(
          groupId: seed.id,
          id: '${seed.id}-tx-main',
          totalAmount: 450000,
          paidAmounts: {currentUserId: 450000},
          shareAmounts: {
            currentUserId: 130000,
            'mock-friend-1': 140000,
            'mock-friend-2': 180000,
          },
          date: now.subtract(const Duration(days: 2)),
          caption: 'Xăng xe đi Đà Lạt',
          categoryName: 'Di chuyển',
          imagePath: 'asset://assets/demo_transactions/transport.png',
          creatorName: 'Minh Anh',
        );
        _addBalancedDemoTransaction(
          groupId: seed.id,
          id: '${seed.id}-tx-dinner',
          totalAmount: 1250000,
          date: now.subtract(const Duration(days: 3)),
          caption: 'Ăn tối nhà hàng',
          categoryName: 'Ăn uống',
          imagePath: 'asset://assets/demo_transactions/lunch.png',
        );
        const remainingTotals = [
          420000,
          320000,
          280000,
          260000,
          250000,
          240000,
          230000,
          220000,
          210000,
          200000,
          175000,
          175000,
        ];
        for (var index = 0; index < remainingTotals.length; index++) {
          _addBalancedDemoTransaction(
            groupId: seed.id,
            id: '${seed.id}-tx-$index',
            totalAmount: remainingTotals[index],
            date: now.subtract(Duration(days: 4 + index)),
            caption: _demoCaption(index),
            categoryName: 'Du lịch',
            imagePath: _demoTransactionImage(index),
          );
        }
      case _DemoBalanceMode.pay:
        _addDemoTransaction(
          groupId: seed.id,
          id: '${seed.id}-tx-main',
          totalAmount: 170000,
          paidAmounts: {'mock-friend-1': 170000},
          shareAmounts: {currentUserId: 85000, 'mock-friend-1': 85000},
          date: now.subtract(const Duration(days: 1)),
        );
        for (var index = 0; index < seed.transactionCount - 1; index++) {
          _addBalancedDemoTransaction(
            groupId: seed.id,
            id: '${seed.id}-tx-$index',
            totalAmount: 100000,
            date: now.subtract(Duration(days: 2 + index)),
          );
        }
      case _DemoBalanceMode.settled:
        for (var index = 0; index < seed.transactionCount; index++) {
          _addBalancedDemoTransaction(
            groupId: seed.id,
            id: '${seed.id}-tx-$index',
            totalAmount: 120000,
            date: now.subtract(Duration(days: 1 + index)),
          );
        }
    }
  }

  void _addBalancedDemoTransaction({
    required String groupId,
    required String id,
    required int totalAmount,
    required DateTime date,
    String? caption,
    String? categoryName,
    String? imagePath,
  }) {
    final members = _activeMembers(groupId).take(2).toList();
    final first = members.first.userId;
    final second = members.length > 1 ? members[1].userId : currentUserId;
    final firstShare = totalAmount ~/ 2;
    final secondShare = totalAmount - firstShare;
    _addDemoTransaction(
      groupId: groupId,
      id: id,
      totalAmount: totalAmount,
      paidAmounts: {first: firstShare, second: secondShare},
      shareAmounts: {first: firstShare, second: secondShare},
      date: date,
      caption: caption,
      categoryName: categoryName,
      imagePath: imagePath,
    );
  }

  void _addDemoTransaction({
    required String groupId,
    required String id,
    required int totalAmount,
    required Map<String, int> paidAmounts,
    required Map<String, int> shareAmounts,
    required DateTime date,
    String? caption,
    String? categoryName,
    String? imagePath,
    String? creatorName,
  }) {
    _transactions[id] = _MockTransactionRecord(
      transaction: GroupTransaction(
        id: id,
        groupId: groupId,
        createdBy: currentUserId,
        totalAmount: totalAmount,
        categoryName: categoryName ?? 'Nhóm',
        caption: caption ?? 'Khoản chi nhóm',
        imagePath: imagePath ?? 'asset://assets/demo_transactions/market.png',
        imageUploadStatus: GroupImageUploadStatus.pending,
        splitMode: GroupSplitMode.equal,
        paymentMode: GroupPaymentMode.multiplePayers,
        splitStatus: GroupSplitStatus.posted,
        transactionDate: date,
        createdAt: date,
        updatedAt: date,
        creatorName: creatorName ?? 'Minh Anh',
      ),
      payers: _payers(id, paidAmounts, date),
      shares: _shares(
        id,
        shareAmounts,
        date,
        submitted: shareAmounts.keys.toSet(),
      ),
      comments: [],
    );
  }

  String _demoCaption(int index) {
    const captions = [
      'Vé tham quan',
      'Cà phê sáng',
      'Mua đồ picnic',
      'Gửi xe',
      'Bữa trưa',
      'Nước uống',
      'Thuê áo khoác',
      'Đồ ăn vặt',
      'Taxi về homestay',
      'Bánh mì đêm',
      'Phụ thu phòng',
      'Quà địa phương',
    ];
    return captions[index % captions.length];
  }

  String _demoTransactionImage(int index) {
    const images = [
      'asset://assets/demo_transactions/shopping.png',
      'asset://assets/demo_transactions/cafe.png',
      'asset://assets/demo_transactions/market.png',
      'asset://assets/demo_transactions/transport.png',
      'asset://assets/demo_transactions/lunch.png',
    ];
    return images[index % images.length];
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
    final groupTransactions = _recordsForGroup(groupId);
    return SpendingGroupDetail(
      group: group.copyWith(
        memberCount: _activeMembers(groupId).length,
        memberAvatarPaths: _activeMembers(
          groupId,
        ).map((member) => member.avatarPath).take(5).toList(growable: false),
        transactionCount: groupTransactions
            .where(
              (record) =>
                  record.transaction.splitStatus == GroupSplitStatus.posted,
            )
            .length,
        totalSpent: groupTransactions
            .where(
              (record) =>
                  record.transaction.splitStatus == GroupSplitStatus.posted,
            )
            .fold<int>(
              0,
              (sum, record) => sum + record.transaction.totalAmount,
            ),
        currentUserBalance: _groupBalances(groupId)[currentUserId] ?? 0,
        hasUnresolvedSettlements:
            _settlements[groupId]?.any(
              (item) =>
                  item.status == GroupSettlementStatus.pending ||
                  item.status == GroupSettlementStatus.payerMarkedPaid,
            ) ??
            false,
      ),
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

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) async {
    _requireAdmin(groupId);
    final group = _groups[groupId];
    if (group == null) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AppException(
        'Group name required',
        code: 'GROUP_NAME_REQUIRED',
      );
    }
    _groups[groupId] = SpendingGroup(
      id: group.id,
      name: trimmedName,
      avatarPath: group.avatarPath,
      description: _blankToNull(description),
      type: _blankToNull(type),
      createdBy: group.createdBy,
      status: group.status,
      createdAt: group.createdAt,
      updatedAt: DateTime.now(),
      memberCount: group.memberCount,
      memberAvatarPaths: group.memberAvatarPaths,
      transactionCount: group.transactionCount,
      totalSpent: group.totalSpent,
      currentUserBalance: group.currentUserBalance,
      hasUnresolvedSettlements: group.hasUnresolvedSettlements,
    );
  }

  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) async {
    _requireAdmin(groupId);
    final group = _groups[groupId];
    if (group == null) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    final hasIncomplete = _recordsForGroup(groupId).any(
      (record) =>
          record.transaction.splitStatus != GroupSplitStatus.posted &&
          record.transaction.splitStatus != GroupSplitStatus.cancelled,
    );
    final hasUnresolved = _groupBalances(
      groupId,
    ).values.any((value) => value != 0);
    final hasPendingSettlement =
        _settlements[groupId]?.any(
          (item) => item.status != GroupSettlementStatus.completed,
        ) ??
        false;
    if (archived && (hasIncomplete || hasUnresolved || hasPendingSettlement)) {
      throw const AppException(
        'Group still has unresolved items',
        code: 'GROUP_ARCHIVE_UNRESOLVED',
      );
    }
    _groups[groupId] = SpendingGroup(
      id: group.id,
      name: group.name,
      avatarPath: group.avatarPath,
      description: group.description,
      type: group.type,
      createdBy: group.createdBy,
      status: archived ? GroupStatus.archived : GroupStatus.active,
      createdAt: group.createdAt,
      updatedAt: DateTime.now(),
      memberCount: group.memberCount,
      memberAvatarPaths: group.memberAvatarPaths,
      transactionCount: group.transactionCount,
      totalSpent: group.totalSpent,
      currentUserBalance: group.currentUserBalance,
      hasUnresolvedSettlements: group.hasUnresolvedSettlements,
    );
  }

  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  }) async {
    _requireAdmin(groupId);
    final group = _groups[groupId];
    if (group == null) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    _groups[groupId] = SpendingGroup(
      id: group.id,
      name: group.name,
      avatarPath: filePath,
      description: group.description,
      type: group.type,
      createdBy: group.createdBy,
      status: group.status,
      createdAt: group.createdAt,
      updatedAt: DateTime.now(),
      memberCount: group.memberCount,
      memberAvatarPaths: group.memberAvatarPaths,
      transactionCount: group.transactionCount,
      totalSpent: group.totalSpent,
      currentUserBalance: group.currentUserBalance,
      hasUnresolvedSettlements: group.hasUnresolvedSettlements,
    );
  }

  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) async {
    _requireAdmin(groupId);
    final group = _groups[groupId];
    if (group == null) {
      throw const AppException('Group not found', code: 'NOT_FOUND');
    }
    final normalized = baseCurrency.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
      throw const AppException('Invalid currency', code: 'CURRENCY_INVALID');
    }
    _groups[groupId] = group.copyWith(baseCurrency: normalized);
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
    _recordActivity(groupId, 'member_joined');
    _notifyActiveMembers(groupId, 'member_joined', excludeCurrentUser: true);
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

  Future<void> declineInvite(String token) async {
    final invite = _inviteLinks[token.trim()];
    if (invite == null) {
      throw const AppException(
        'Invalid group invite',
        code: 'GROUP_INVITE_INVALID',
      );
    }
    if (invite.status == GroupInviteStatus.active) {
      invite.status = GroupInviteStatus.revoked;
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
    _requireGroup(groupId);
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

  Future<List<GroupTransaction>> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async {
    final normalized = query.trim().toLowerCase();
    final values = _recordsForGroup(groupId)
        .map((record) => record.transaction)
        .where((transaction) {
          if (status == 'posted' &&
              transaction.splitStatus != GroupSplitStatus.posted) {
            return false;
          }
          if (status == 'pending' &&
              (transaction.splitStatus == GroupSplitStatus.posted ||
                  transaction.splitStatus == GroupSplitStatus.cancelled)) {
            return false;
          }
          if (normalized.isEmpty) return true;
          return [
            transaction.caption,
            transaction.categoryName,
            transaction.note,
            transaction.creatorName,
          ].whereType<String>().join(' ').toLowerCase().contains(normalized);
        })
        .toList(growable: false);
    final start = offset.clamp(0, values.length);
    final end = (start + limit + 1).clamp(start, values.length);
    return values.sublist(start, end);
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
    final participantIds = draft.participantIds.isEmpty
        ? memberIds
        : draft.participantIds;
    final now = DateTime.now();
    final id = _id('transaction');
    late final Map<String, int> shares;
    late final Map<String, int> paidAmounts;
    late final GroupSplitStatus splitStatus;
    if (draft.splitMode != GroupSplitMode.unequal) {
      final result = _splitCalculator.calculate(
        totalAmount: draft.totalAmount,
        activeMemberIds: memberIds,
        participantIds: participantIds,
        splitMode: draft.splitMode,
        paymentMode: draft.paymentMode,
        unequalShares: draft.shareAmounts,
        payerAmounts: draft.payerAmounts,
      );
      shares = result.shares;
      paidAmounts = result.paidAmounts;
      splitStatus = GroupSplitStatus.posted;
    } else {
      _splitCalculator.validateDraft(
        totalAmount: draft.totalAmount,
        activeMemberIds: memberIds,
        participantIds: participantIds,
        splitMode: draft.splitMode,
        paymentMode: draft.paymentMode,
        payerAmounts: draft.payerAmounts,
      );
      shares = {for (final id in participantIds) id: 0};
      paidAmounts = draft.paymentMode == GroupPaymentMode.everyonePaid
          ? {for (final id in memberIds) id: 0}
          : {for (final id in memberIds) id: draft.payerAmounts[id] ?? 0};
      splitStatus = GroupSplitStatus.pendingMemberAmountInput;
    }

    final transaction = GroupTransaction(
      id: id,
      groupId: draft.groupId,
      createdBy: currentUserId,
      totalAmount: (draft.totalAmount / draft.exchangeRateToBase).round(),
      baseTotalAmount: draft.totalAmount,
      currencyCode: draft.currencyCode,
      exchangeRateToBase: draft.exchangeRateToBase,
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
        submitted: draft.splitMode != GroupSplitMode.unequal
            ? participantIds.toSet()
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
        baseTotalAmount: replacement.transaction.baseTotalAmount,
        currencyCode: replacement.transaction.currencyCode,
        exchangeRateToBase: replacement.transaction.exchangeRateToBase,
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

  Future<List<GroupNotification>> fetchNotifications({String? category}) async {
    _seedDemoNotificationsIfNeeded();
    final items = _notifications[currentUserId] ?? const [];
    final filtered = category == null
        ? items
        : items.where((item) => item.category == category).toList();
    return List.unmodifiable(filtered);
  }

  void _seedDemoNotificationsIfNeeded() {
    if (currentUserId != _demoUserId) return;
    if ((_notifications[_demoUserId] ?? const []).isNotEmpty) return;
    if (_groups.isEmpty) return;
    final now = DateTime.now();
    _notifications[_demoUserId] = [
      GroupNotification(
        id: _id('notification'),
        groupId: 'mock-group-dalat',
        groupName: _groups['mock-group-dalat']?.name ?? 'Đà Lạt 6/2025',
        type: 'transaction_posted',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      GroupNotification(
        id: _id('notification'),
        groupId: 'mock-group-home-q3',
        groupName: _groups['mock-group-home-q3']?.name ?? 'Nhà chung Q3',
        type: 'member_amount_required',
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      GroupNotification(
        id: _id('notification'),
        groupId: 'mock-group-cafe-weekend',
        groupName: _groups['mock-group-cafe-weekend']?.name ?? 'Cafe cuối tuần',
        type: 'debt_settled',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
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
      category: item.category,
    );
  }

  Future<void> markAllNotificationsRead() async {
    final notifications = _notifications[currentUserId] ?? [];
    for (var index = 0; index < notifications.length; index++) {
      final item = notifications[index];
      if (item.isRead) continue;
      notifications[index] = GroupNotification(
        id: item.id,
        groupId: item.groupId,
        groupName: item.groupName,
        type: item.type,
        isRead: true,
        createdAt: item.createdAt,
        groupTransactionId: item.groupTransactionId,
        inviteToken: item.inviteToken,
        category: item.category,
      );
    }
  }

  Future<List<GroupActivity>> fetchActivities(String groupId) async {
    _requireGroup(groupId);
    final result = List<GroupActivity>.from(_activities[groupId] ?? const []);
    result.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return List.unmodifiable(result);
  }

  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) async {
    _requireActiveMember(groupId);
    return _notificationPreferences[_preferenceKey(groupId, currentUserId)] ??
        GroupNotificationPreference.defaults(groupId);
  }

  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  ) async {
    _requireActiveMember(preference.groupId);
    _notificationPreferences[_preferenceKey(
          preference.groupId,
          currentUserId,
        )] =
        preference;
  }

  Future<List<GroupReactionSummary>> fetchReactionSummaries(
    String transactionId,
  ) async {
    final record = _requireTransaction(transactionId);
    _requireActiveMember(record.transaction.groupId);
    final reactions =
        _reactions[transactionId] ?? const <String, Set<String>>{};
    final result =
        reactions.entries
            .where((entry) => entry.value.isNotEmpty)
            .map(
              (entry) => GroupReactionSummary(
                emoji: entry.key,
                count: entry.value.length,
                reactedByCurrentUser: entry.value.contains(currentUserId),
              ),
            )
            .toList()
          ..sort((left, right) => right.count.compareTo(left.count));
    return List.unmodifiable(result);
  }

  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) async {
    final record = _requireTransaction(transactionId);
    _requireActiveMember(record.transaction.groupId);
    final normalized = emoji.trim();
    if (normalized.isEmpty) {
      throw const AppException(
        'Reaction required',
        code: 'GROUP_REACTION_REQUIRED',
      );
    }
    final byEmoji = _reactions.putIfAbsent(transactionId, () => {});
    final users = byEmoji.putIfAbsent(normalized, () => <String>{});
    if (!users.add(currentUserId)) {
      users.remove(currentUserId);
    }
    _recordActivity(
      record.transaction.groupId,
      'transaction_reacted',
      metadata: {'transactionId': transactionId, 'emoji': normalized},
    );
  }

  Future<GroupBudget> fetchBudget(String groupId) async {
    _requireActiveMember(groupId);
    return _budgets[groupId] ?? GroupBudget.defaults(groupId);
  }

  Future<void> updateBudget(GroupBudget budget) async {
    _requireAdmin(budget.groupId);
    if (budget.monthlyLimit < 0) {
      throw const AppException(
        'Budget must be non-negative',
        code: 'GROUP_BUDGET_INVALID',
      );
    }
    _budgets[budget.groupId] = budget;
    _recordActivity(
      budget.groupId,
      'budget_updated',
      metadata: {'monthlyLimit': budget.monthlyLimit},
    );
  }

  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) async {
    _requireActiveMember(groupId);
    final result =
        _recurringTransactions.values
            .where((item) => item.groupId == groupId)
            .toList()
          ..sort((left, right) => left.nextRunAt.compareTo(right.nextRunAt));
    return List.unmodifiable(result);
  }

  Future<void> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  }) async {
    _requireActiveMember(groupId);
    if (title.trim().isEmpty || amount <= 0) {
      throw const AppException(
        'Recurring transaction invalid',
        code: 'GROUP_RECURRING_INVALID',
      );
    }
    final now = DateTime.now();
    final id = _id('recurring');
    _recurringTransactions[id] = GroupRecurringTransaction(
      id: id,
      groupId: groupId,
      createdBy: currentUserId,
      title: title.trim(),
      amount: amount,
      frequency: frequency,
      nextRunAt: nextRunAt,
      notifyDaysBefore: notifyDaysBefore,
      isActive: true,
      createdAt: now,
    );
    _recordActivity(
      groupId,
      'recurring_created',
      metadata: {'recurringId': id},
    );
    _notifyActiveMembers(
      groupId,
      'recurring_created',
      excludeCurrentUser: false,
    );
  }

  Future<GroupPublicProfile> fetchPublicProfile(String groupId) async {
    _requireActiveMember(groupId);
    return _publicProfiles[groupId] ??
        GroupPublicProfile.defaults(
          groupId,
        ).copyWith(slug: _slug(_requireGroup(groupId).name));
  }

  Future<void> updatePublicProfile(GroupPublicProfile profile) async {
    _requireAdmin(profile.groupId);
    _publicProfiles[profile.groupId] = profile.copyWith(
      slug: profile.slug?.trim().isNotEmpty == true
          ? _slug(profile.slug!)
          : _slug(_requireGroup(profile.groupId).name),
    );
    _recordActivity(
      profile.groupId,
      'public_profile_updated',
      metadata: {'enabled': profile.isEnabled},
    );
  }

  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) async {
    _requireGroup(groupId);
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final records = _recordsForGroup(groupId).where((record) {
      final date = record.transaction.transactionDate;
      return record.transaction.splitStatus == GroupSplitStatus.posted &&
          !date.isBefore(start) &&
          date.isBefore(end);
    }).toList();

    final categoryTotals = <String, ({int amount, int count})>{};
    final memberTotals = <String, ({int share, int paid, int count})>{};
    for (final record in records) {
      final category = record.transaction.categoryName ?? 'Uncategorized';
      final categoryValue = categoryTotals[category] ?? (amount: 0, count: 0);
      categoryTotals[category] = (
        amount: categoryValue.amount + record.transaction.totalAmount,
        count: categoryValue.count + 1,
      );
      final users = <String>{
        ...record.shares.map((share) => share.userId),
        ...record.payers.map((payer) => payer.userId),
      };
      for (final userId in users) {
        final current = memberTotals[userId] ?? (share: 0, paid: 0, count: 0);
        final share = record.shares
            .where((item) => item.userId == userId)
            .fold<int>(0, (sum, item) => sum + item.shareAmount);
        final paid = record.payers
            .where((item) => item.userId == userId)
            .fold<int>(0, (sum, item) => sum + item.paidAmount);
        memberTotals[userId] = (
          share: current.share + share,
          paid: current.paid + paid,
          count: current.count + 1,
        );
      }
    }

    final names = {
      for (final member in _members[groupId] ?? const <SpendingGroupMember>[])
        member.userId: member.resolvedName,
    };
    final categories = categoryTotals.entries.toList()
      ..sort((left, right) => right.value.amount.compareTo(left.value.amount));
    final members = memberTotals.entries.toList()
      ..sort((left, right) => right.value.share.compareTo(left.value.share));
    return GroupMonthlyStats(
      groupId: groupId,
      month: start,
      totalSpent: records.fold<int>(
        0,
        (sum, record) => sum + record.transaction.totalAmount,
      ),
      transactionCount: records.length,
      topCategoryName: categories.isEmpty ? null : categories.first.key,
      topCategoryAmount: categories.isEmpty ? 0 : categories.first.value.amount,
      categoryBreakdown: categories
          .map(
            (item) => GroupCategorySpending(
              categoryName: item.key,
              totalAmount: item.value.amount,
              transactionCount: item.value.count,
            ),
          )
          .toList(growable: false),
      memberBreakdown: members
          .map(
            (item) => GroupMemberBreakdown(
              userId: item.key,
              displayName: names[item.key] ?? item.key,
              shareAmount: item.value.share,
              paidAmount: item.value.paid,
              balance: item.value.share - item.value.paid,
              transactionCount: item.value.count,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) async {
    _requireGroup(groupId);
    return (_settlements[groupId] ?? const <GroupSettlementSuggestion>[])
        .where((item) => item.status != GroupSettlementStatus.pending)
        .map(
          (item) => GroupSettlementHistoryEntry(
            id: item.id,
            fromName: item.fromDisplayName ?? item.fromUserId,
            toName: item.toDisplayName ?? item.toUserId,
            amount: item.amount,
            status: item.status.value,
            updatedAt: item.updatedAt,
          ),
        )
        .toList(growable: false);
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

  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  }) async {
    final match = _findSettlement(settlementId);
    final isParticipant =
        match.item.fromUserId == currentUserId ||
        match.item.toUserId == currentUserId;
    if (!isParticipant ||
        match.item.status == GroupSettlementStatus.completed ||
        match.item.status == GroupSettlementStatus.disputed ||
        reason.trim().isEmpty) {
      throw const AppException(
        'Settlement cannot be disputed',
        code: 'GROUP_SETTLEMENT_FORBIDDEN',
      );
    }
    match.list[match.index] = _copySettlement(
      match.item,
      status: GroupSettlementStatus.disputed,
    );
    _recordActivity(
      match.item.groupId,
      'settlement_disputed',
      metadata: {'settlement_id': settlementId, 'reason': reason.trim()},
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

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    final members = _members[groupId];
    if (members == null || userId == currentUserId) {
      throw const AppException(
        'Member cannot be removed',
        code: 'GROUP_MEMBER_REMOVE_FORBIDDEN',
      );
    }
    final actorIndex = members.indexWhere(
      (member) =>
          member.userId == currentUserId &&
          member.status == GroupMemberStatus.active,
    );
    final targetIndex = members.indexWhere(
      (member) =>
          member.userId == userId &&
          (member.status == GroupMemberStatus.active ||
              member.status == GroupMemberStatus.invited),
    );
    if (actorIndex < 0 || targetIndex < 0) {
      throw const AppException('Member not found', code: 'NOT_FOUND');
    }
    final actor = members[actorIndex];
    final target = members[targetIndex];
    final canRemove =
        actor.role == GroupRole.owner ||
        (actor.role == GroupRole.admin && target.role == GroupRole.member);
    if (!canRemove || target.role == GroupRole.owner) {
      throw const AppException(
        'Member cannot be removed',
        code: 'GROUP_MEMBER_REMOVE_FORBIDDEN',
      );
    }
    final unresolved =
        _settlements[groupId]?.any(
          (settlement) =>
              (settlement.fromUserId == userId ||
                  settlement.toUserId == userId) &&
              settlement.status != GroupSettlementStatus.completed,
        ) ??
        false;
    if ((_groupBalances(groupId)[userId] ?? 0) != 0 || unresolved) {
      throw const AppException(
        'Member has unresolved group balance',
        code: 'GROUP_MEMBER_REMOVE_UNRESOLVED',
      );
    }
    members[targetIndex] = _memberWith(
      target,
      status: GroupMemberStatus.removed,
      leftAt: DateTime.now(),
    );
    _recordActivity(
      groupId,
      'member_removed',
      metadata: {'removed_user_id': userId},
    );
  }

  Future<void> leaveGroup(String groupId) async {
    final detail = await fetchGroupDetail(groupId);
    final balance = _groupBalances(groupId)[currentUserId] ?? 0;
    final incompleteTransaction = _recordsForGroup(groupId).any(
      (record) =>
          record.transaction.createdBy == currentUserId &&
          record.transaction.splitStatus != GroupSplitStatus.posted &&
          record.transaction.splitStatus != GroupSplitStatus.cancelled,
    );
    final unresolved =
        _settlements[groupId]?.any(
          (item) =>
              (item.fromUserId == currentUserId ||
                  item.toUserId == currentUserId) &&
              item.status != GroupSettlementStatus.completed,
        ) ??
        false;
    if (incompleteTransaction) {
      throw const AppException(
        'Incomplete group transaction',
        code: 'GROUP_LEAVE_INCOMPLETE_TRANSACTION',
      );
    }
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
    _notifyActiveMembers(groupId, 'member_left', excludeCurrentUser: true);
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
    _recordActivity(
      record.transaction.groupId,
      'comment_added',
      metadata: {'transactionId': transactionId},
    );
    final mentionedUsers = _mentionedUserIds(
      record.transaction.groupId,
      trimmed,
    );
    for (final userId in mentionedUsers) {
      if (userId == currentUserId) continue;
      _notifyUser(
        groupId: record.transaction.groupId,
        userId: userId,
        type: 'comment_mention',
        transactionId: transactionId,
      );
    }
  }

  Future<List<GroupReactionSummary>> fetchReactions(
    String transactionId,
  ) async {
    final byEmoji = _reactions[transactionId] ?? const {};
    final summaries = byEmoji.entries
        .map(
          (entry) => GroupReactionSummary(
            emoji: entry.key,
            count: entry.value.length,
            reactedByCurrentUser: entry.value.contains(currentUserId),
          ),
        )
        .where((summary) => summary.count > 0)
        .toList();
    summaries.sort((a, b) => b.count.compareTo(a.count));
    return summaries;
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

  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId) async {
    _requireActiveMember(groupId);
    return const [];
  }

  Future<List<GroupPoll>> fetchPolls(String groupId) async {
    _requireActiveMember(groupId);
    return const [];
  }

  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) async {
    _requireActiveMember(groupId);
    return _id('poll');
  }

  Future<void> votePoll({
    required String pollId,
    required String optionId,
  }) async {}

  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(
    String groupId,
  ) async {
    _requireActiveMember(groupId);
    return const [];
  }

  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _requireAdmin(groupId);
    return _id('challenge');
  }

  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  }) async {}

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
    for (final member in _activeMembers(groupId)) {
      if (excludeCurrentUser && member.userId == currentUserId) continue;
      _notifyUser(
        groupId: groupId,
        userId: member.userId,
        type: type,
        transactionId: transactionId,
      );
    }
  }

  void _notifyUser({
    required String groupId,
    required String userId,
    required String type,
    String? transactionId,
  }) {
    final group = _groups[groupId];
    if (group == null || !_notificationEnabled(groupId, userId, type)) return;
    final notification = GroupNotification(
      id: _id('notification'),
      groupId: groupId,
      groupName: group.name,
      groupTransactionId: transactionId,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications[userId] = [notification, ...?_notifications[userId]];
  }

  bool _notificationEnabled(String groupId, String userId, String type) {
    final preference =
        _notificationPreferences[_preferenceKey(groupId, userId)] ??
        GroupNotificationPreference.defaults(groupId);
    if (preference.muteAll) return false;
    final hour = DateTime.now().hour;
    final start = preference.quietHoursStart;
    final end = preference.quietHoursEnd;
    if (start != null && end != null) {
      final inQuietHours = start <= end
          ? hour >= start && hour < end
          : hour >= start || hour < end;
      if (inQuietHours) return false;
    }
    if (type.contains('invite')) return preference.inviteNotifications;
    if (type.contains('mention')) return preference.mentionNotifications;
    if (type.contains('settlement') || type.contains('debt')) {
      return preference.debtNotifications;
    }
    if (type.contains('transaction') || type.contains('amount')) {
      return preference.transactionNotifications;
    }
    return true;
  }

  Set<String> _mentionedUserIds(String groupId, String content) {
    final usernames = RegExp(
      r'@([a-zA-Z0-9_]{3,30})',
    ).allMatches(content).map((match) => match.group(1)!.toLowerCase()).toSet();
    if (usernames.isEmpty) return const {};
    return _activeMembers(groupId)
        .where(
          (member) =>
              member.username != null &&
              usernames.contains(member.username!.toLowerCase()),
        )
        .map((member) => member.userId)
        .toSet();
  }

  String? _displayName(String groupId, String userId) {
    final members = _members[groupId] ?? const <SpendingGroupMember>[];
    for (final member in members) {
      if (member.userId == userId) return member.resolvedName;
    }
    return userId;
  }

  String _preferenceKey(String groupId, String userId) => '$groupId:$userId';

  String _slug(String value) {
    final normalized = value.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
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

  SpendingGroupMember _memberWith(
    SpendingGroupMember value, {
    GroupRole? role,
    GroupMemberStatus? status,
    DateTime? leftAt,
  }) {
    return SpendingGroupMember(
      id: value.id,
      groupId: value.groupId,
      userId: value.userId,
      role: role ?? value.role,
      status: status ?? value.status,
      joinedAt: value.joinedAt,
      leftAt: leftAt ?? value.leftAt,
      displayName: value.displayName,
      username: value.username,
      avatarPath: value.avatarPath,
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

class _DemoGroupSeed {
  const _DemoGroupSeed({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.transactionCount,
    required this.colorName,
    required this.avatarPath,
    required this.createdAt,
    required this.balanceMode,
  });

  final String id;
  final String name;
  final int memberCount;
  final int transactionCount;
  final String colorName;
  final String avatarPath;
  final DateTime createdAt;
  final _DemoBalanceMode balanceMode;
}

enum _DemoBalanceMode { receive, pay, settled }

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
