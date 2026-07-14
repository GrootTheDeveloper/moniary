import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_mock_data_source.dart';
import '../datasources/group_supabase_data_source.dart';
import '../models/group_model_mapper.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final useMockData =
      ref.watch(useMockDataModeProvider) || !AppConstants.hasSupabaseConfig;
  final currentUserId = ref.watch(currentSessionProvider)?.user.id ?? '';
  return GroupRepositoryImpl(
    client,
    useMockData: useMockData,
    mockDataSource: GroupMockDataSource(currentUserId: currentUserId),
  );
});

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(
    SupabaseClient client, {
    required bool useMockData,
    required GroupMockDataSource mockDataSource,
  }) : _client = client,
       _useMockData = useMockData,
       _mock = mockDataSource,
       _remote = GroupSupabaseDataSource(client);

  final SupabaseClient _client;
  final bool _useMockData;
  final GroupMockDataSource _mock;
  final GroupSupabaseDataSource _remote;

  @override
  String get currentUserId {
    if (_useMockData) {
      return _mock.currentUserId;
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  @override
  Future<List<SpendingGroup>> fetchGroups() async {
    if (_useMockData) {
      return _mock.fetchGroups();
    }
    return _guard('fetch groups', () async {
      final groups = await _remote.fetchGroups();
      final result = <SpendingGroup>[];
      for (final row in groups) {
        final groupId = row['id'] as String;
        final members = await _remote.fetchMembers(groupId);
        final transactions = await _remote.fetchTransactions(groupId);
        final settlements = await _remote.fetchSettlements(groupId);
        final balances = await _remote.fetchBalances(groupId);
        final ownBalance = balances
            .where((item) => item['user_id'] == currentUserId)
            .fold<int>(
              0,
              (sum, item) => sum + (item['balance'] as num).toInt(),
            );
        result.add(
          GroupModelMapper.group(
            row,
            memberCount: members
                .where((item) => item['status'] == 'active')
                .length,
            memberAvatarPaths: members
                .where((item) => item['status'] == 'active')
                .map((item) {
                  final profile = item['profile'] as Map<String, dynamic>?;
                  return profile?['avatar_url'] as String?;
                })
                .take(5)
                .toList(growable: false),
            transactionCount: transactions
                .where((item) => item['split_status'] == 'posted')
                .length,
            totalSpent: transactions
                .where((item) => item['split_status'] == 'posted')
                .fold<int>(
                  0,
                  (sum, item) => sum + (item['total_amount'] as num).toInt(),
                ),
            currentUserBalance: ownBalance,
            hasUnresolvedSettlements: settlements.any(
              (item) =>
                  item['status'] == 'pending' ||
                  item['status'] == 'payer_marked_paid',
            ),
          ),
        );
      }
      return result;
    });
  }

  @override
  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) async {
    if (_useMockData) {
      return _mock.fetchGroupDetail(groupId);
    }
    return _guard('fetch group detail', () async {
      final group = GroupModelMapper.group(await _remote.fetchGroup(groupId));
      final members = (await _remote.fetchMembers(
        groupId,
      )).map(GroupModelMapper.member).toList();
      final currentMember = members.where(
        (member) =>
            member.userId == currentUserId &&
            member.status == GroupMemberStatus.active,
      );
      if (currentMember.isEmpty) {
        throw const AppException('Group not found', code: 'NOT_FOUND');
      }
      return SpendingGroupDetail(
        group: group.copyWith(
          memberCount: members.where((member) => member.isActive).length,
        ),
        members: members,
        currentUserRole: currentMember.first.role,
      );
    });
  }

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
    String? avatarFilePath,
  }) async {
    if (_useMockData) {
      return _mock.createGroup(
        name: name,
        description: description,
        type: type,
      );
    }
    return _guard('create group', () async {
      final groupId = await _remote.createGroup(
        name: name,
        description: description,
        type: type,
      );
      if (avatarFilePath != null) {
        await _remote.uploadGroupAvatar(
          groupId: groupId,
          filePath: avatarFilePath,
        );
      }
      return groupId;
    });
  }

  @override
  Future<String> createInviteLink(String groupId) {
    if (_useMockData) {
      return _mock.createInviteLink(groupId);
    }
    return _guard(
      'create group invite link',
      () => _remote.createInviteLink(groupId),
    );
  }

  @override
  Future<GroupInvitePreview> fetchInvitePreview(String token) {
    if (_useMockData) return _mock.fetchInvitePreview(token);
    return _guard('fetch group invite preview', () async {
      final row = await _remote.fetchInvitePreview(token.trim());
      return GroupInvitePreview(
        status: GroupInviteStatusValue.fromValue(row['status'] as String?),
        groupId: row['group_id'] as String?,
        groupName: row['group_name'] as String?,
        groupAvatarPath: row['group_avatar_path'] as String?,
        inviterName: row['inviter_name'] as String?,
        expiresAt: row['expires_at'] is String
            ? DateTime.tryParse(row['expires_at'] as String)
            : null,
      );
    });
  }

  @override
  Future<GroupInviteAcceptResult> acceptInvite(String token) {
    if (_useMockData) return _mock.acceptInvite(token);
    return _guard('accept group invite link', () async {
      final row = await _remote.acceptInvite(token.trim());
      return GroupInviteAcceptResult(
        status: GroupInviteStatusValue.fromValue(row['status'] as String?),
        groupId: row['group_id'] as String,
      );
    });
  }

  @override
  Future<void> revokeInviteLink(String token) {
    if (_useMockData) return _mock.revokeInviteLink(token);
    return _guard(
      'revoke group invite link',
      () => _remote.revokeInviteLink(token.trim()),
    );
  }

  @override
  Future<List<GroupDirectInvite>> fetchDirectInvites() {
    if (_useMockData) return _mock.fetchDirectInvites();
    return _guard('fetch direct group invites', () async {
      return (await _remote.fetchDirectInvites()).map((row) {
        return GroupDirectInvite(
          id: row['id'] as String,
          groupId: row['group_id'] as String,
          groupName: row['group_name'] as String? ?? '',
          groupAvatarPath: row['group_avatar_path'] as String?,
          inviterName: row['inviter_name'] as String? ?? '',
          status: GroupDirectInviteStatusValue.fromValue(
            row['status'] as String?,
          ),
          createdAt: DateTime.parse(row['created_at'] as String),
          expiresAt: DateTime.parse(row['expires_at'] as String),
        );
      }).toList();
    });
  }

  @override
  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId) {
    if (_useMockData) return _mock.acceptDirectInvite(inviteId);
    return _guard('accept direct group invite', () async {
      final row = await _remote.acceptDirectInvite(inviteId);
      return GroupInviteAcceptResult(
        status: GroupInviteStatusValue.fromValue(row['status'] as String?),
        groupId: row['group_id'] as String,
      );
    });
  }

  @override
  Future<void> declineDirectInvite(String inviteId) {
    if (_useMockData) return _mock.declineDirectInvite(inviteId);
    return _guard(
      'decline direct group invite',
      () => _remote.declineDirectInvite(inviteId),
    );
  }

  @override
  Future<void> declineInvite(String token) {
    if (_useMockData) {
      return _mock.declineInvite(token);
    }
    return _guard('decline group invite', () => _remote.declineInvite(token));
  }

  @override
  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) {
    if (_useMockData) {
      return _mock.inviteByUsername(groupId: groupId, username: username);
    }
    return _guard(
      'invite group member',
      () => _remote.inviteByUsername(groupId: groupId, username: username),
    );
  }

  @override
  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) {
    if (_useMockData) {
      return _mock.inviteByUserId(groupId: groupId, userId: userId);
    }
    return _guard(
      'invite group member by user id',
      () => _remote.inviteByUserId(groupId: groupId, userId: userId),
    );
  }

  @override
  Future<List<GroupTransaction>> fetchTransactions(String groupId) {
    if (_useMockData) {
      return _mock.fetchTransactions(groupId);
    }
    return _guard('fetch group transactions', () async {
      return (await _remote.fetchTransactions(
        groupId,
      )).map(GroupModelMapper.transaction).toList();
    });
  }

  @override
  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId) {
    if (_useMockData) {
      return _mock.fetchTransactionDetail(transactionId);
    }
    return _guard('fetch group transaction detail', () async {
      final transactionRow = await _remote.fetchTransaction(transactionId);
      final groupId = transactionRow['group_id'] as String;
      final settlements = await _remote.fetchSettlements(groupId);
      transactionRow['has_completed_settlement'] = settlements.any(
        (item) => item['status'] == 'completed',
      );
      final transaction = GroupModelMapper.transaction(transactionRow);
      final payers = (await _remote.fetchPayers(
        transactionId,
      )).map(GroupModelMapper.payer).toList();
      final shares = (await _remote.fetchShares(
        transactionId,
      )).map(GroupModelMapper.share).toList();
      final comments = (await _remote.fetchComments(
        transactionId,
      )).map(GroupModelMapper.comment).toList();
      return GroupTransactionDetail(
        transaction: transaction,
        payers: payers,
        shares: shares,
        comments: comments,
      );
    });
  }

  @override
  Future<String> createTransaction(GroupTransactionDraft draft) async {
    if (_useMockData) {
      return _mock.createTransaction(draft);
    }
    return _guard('create group transaction', () async {
      final id = await _remote.createTransaction(draft);
      if (draft.imageFilePath != null) {
        try {
          await _remote.uploadTransactionImage(
            groupId: draft.groupId,
            transactionId: id,
            filePath: draft.imageFilePath!,
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'Group transaction image upload failed',
            error,
            stackTrace,
          );
          await _remote.markImageUploadFailed(id);
        }
      }
      return id;
    });
  }

  @override
  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) async {
    if (_useMockData) {
      return _mock.updateTransaction(
        transactionId: transactionId,
        draft: draft,
      );
    }
    return _guard('update group transaction', () async {
      await _remote.updateTransaction(
        transactionId: transactionId,
        draft: draft,
      );
      if (draft.imageFilePath != null) {
        try {
          await _remote.uploadTransactionImage(
            groupId: draft.groupId,
            transactionId: transactionId,
            filePath: draft.imageFilePath!,
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'Group transaction image upload failed',
            error,
            stackTrace,
          );
          await _remote.markImageUploadFailed(transactionId);
        }
      }
    });
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    if (_useMockData) {
      return _mock.deleteTransaction(transactionId);
    }
    return _guard(
      'delete group transaction',
      () => _remote.deleteTransaction(transactionId),
    );
  }

  @override
  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  }) {
    if (_useMockData) {
      return _mock.submitMemberAmount(
        transactionId: transactionId,
        shareAmount: shareAmount,
      );
    }
    return _guard(
      'submit group member amount',
      () => _remote.submitMemberAmount(
        transactionId: transactionId,
        shareAmount: shareAmount,
      ),
    );
  }

  @override
  Future<GroupSettlementOverview> fetchSettlementOverview(String groupId) {
    if (_useMockData) {
      return _mock.fetchSettlementOverview(groupId);
    }
    return _guard('fetch group settlements', () async {
      final detail = await fetchGroupDetail(groupId);
      final names = {
        for (final member in detail.members) member.userId: member.resolvedName,
      };
      final balances = (await _remote.fetchBalances(groupId)).map((row) {
        final balance = GroupModelMapper.balance(row);
        return GroupBalance(
          groupId: balance.groupId,
          userId: balance.userId,
          totalShareAmount: balance.totalShareAmount,
          totalPaidAmount: balance.totalPaidAmount,
          balance: balance.balance,
          displayName: names[balance.userId],
        );
      }).toList();
      final settlements = (await _remote.fetchSettlements(
        groupId,
      )).map(GroupModelMapper.settlement).toList();
      return GroupSettlementOverview(
        balances: balances,
        suggestions: settlements,
      );
    });
  }

  @override
  Future<GroupStatsOverview> fetchStats(String groupId) {
    if (_useMockData) {
      return _mock.fetchStats(groupId);
    }
    return _guard('fetch group stats', () async {
      final detail = await fetchGroupDetail(groupId);
      final transactions = await fetchTransactions(groupId);
      final settlement = await fetchSettlementOverview(groupId);
      return _buildStats(
        detail: detail,
        transactions: transactions,
        settlement: settlement,
        currentUserId: currentUserId,
      );
    });
  }

  @override
  Future<List<GroupNotification>> fetchNotifications() {
    if (_useMockData) {
      return _mock.fetchNotifications();
    }
    return _guard('fetch group notifications', () async {
      return (await _remote.fetchNotifications())
          .map(GroupModelMapper.notification)
          .toList();
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    if (_useMockData) {
      return _mock.markNotificationRead(notificationId);
    }
    return _guard(
      'mark group notification read',
      () => _remote.markNotificationRead(notificationId),
    );
  }

  @override
  Future<List<GroupActivity>> fetchActivities(String groupId) {
    if (_useMockData) {
      return _mock.fetchActivities(groupId);
    }
    return _guard('fetch group activities', () async {
      return (await _remote.fetchActivities(
        groupId,
      )).map(GroupModelMapper.activity).toList();
    });
  }

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) {
    if (_useMockData) {
      return _mock.fetchNotificationPreference(groupId);
    }
    return _guard('fetch group notification preference', () async {
      return GroupModelMapper.notificationPreference(
        await _remote.fetchNotificationPreference(groupId),
      );
    });
  }

  @override
  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    if (_useMockData) {
      return _mock.updateNotificationPreference(preference);
    }
    return _guard(
      'update group notification preference',
      () => _remote.updateNotificationPreference(preference),
    );
  }

  @override
  Future<List<GroupReactionSummary>> fetchReactionSummaries(
    String transactionId,
  ) {
    if (_useMockData) {
      return _mock.fetchReactionSummaries(transactionId);
    }
    return _guard('fetch group transaction reactions', () async {
      return (await _remote.fetchReactionSummaries(
        transactionId,
      )).map(GroupModelMapper.reactionSummary).toList();
    });
  }

  @override
  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) {
    if (_useMockData) {
      return _mock.toggleReaction(transactionId: transactionId, emoji: emoji);
    }
    return _guard(
      'toggle group transaction reaction',
      () => _remote.toggleReaction(transactionId: transactionId, emoji: emoji),
    );
  }

  @override
  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) {
    return _guard('fetch group monthly stats', () async {
      final detail = await fetchGroupDetail(groupId);
      final transactions = await fetchTransactions(groupId);
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      final posted = transactions
          .where(
            (item) =>
                item.splitStatus == GroupSplitStatus.posted &&
                !item.transactionDate.isBefore(start) &&
                item.transactionDate.isBefore(end),
          )
          .toList();
      final categories = <String, ({int amount, int count})>{};
      final members = {
        for (final member in detail.activeMembers)
          member.userId: _MemberStats(member.resolvedName),
      };
      for (final transaction in posted) {
        final category = transaction.categoryName?.trim().isNotEmpty == true
            ? transaction.categoryName!
            : 'Chưa chọn danh mục';
        final currentCategory = categories[category] ?? (amount: 0, count: 0);
        categories[category] = (
          amount: currentCategory.amount + transaction.totalAmount,
          count: currentCategory.count + 1,
        );

        final txDetail = await fetchTransactionDetail(transaction.id);
        final touchedMembers = <String>{};
        for (final share in txDetail.shares) {
          final member = members.putIfAbsent(
            share.userId,
            () => _MemberStats(
              share.displayName?.trim().isNotEmpty == true
                  ? share.displayName!
                  : share.userId,
            ),
          );
          member.shareAmount += share.shareAmount;
          touchedMembers.add(share.userId);
        }
        for (final payer in txDetail.payers) {
          final member = members.putIfAbsent(
            payer.userId,
            () => _MemberStats(
              payer.displayName?.trim().isNotEmpty == true
                  ? payer.displayName!
                  : payer.userId,
            ),
          );
          member.paidAmount += payer.paidAmount;
          touchedMembers.add(payer.userId);
        }
        for (final userId in touchedMembers) {
          members[userId]?.transactionCount += 1;
        }
      }
      final categoryBreakdown =
          categories.entries
              .map(
                (entry) => GroupCategorySpending(
                  categoryName: entry.key,
                  totalAmount: entry.value.amount,
                  transactionCount: entry.value.count,
                ),
              )
              .toList()
            ..sort(
              (left, right) => right.totalAmount.compareTo(left.totalAmount),
            );
      final topCategory = categoryBreakdown.isEmpty
          ? null
          : categoryBreakdown.first;
      final memberBreakdown =
          members.entries
              .map(
                (entry) => GroupMemberBreakdown(
                  userId: entry.key,
                  displayName: entry.value.displayName,
                  shareAmount: entry.value.shareAmount,
                  paidAmount: entry.value.paidAmount,
                  balance: entry.value.shareAmount - entry.value.paidAmount,
                  transactionCount: entry.value.transactionCount,
                ),
              )
              .toList()
            ..sort(
              (left, right) => right.shareAmount.compareTo(left.shareAmount),
            );
      return GroupMonthlyStats(
        groupId: groupId,
        month: start,
        totalSpent: posted.fold<int>(
          0,
          (sum, transaction) => sum + transaction.totalAmount,
        ),
        transactionCount: posted.length,
        topCategoryName: topCategory?.categoryName,
        topCategoryAmount: topCategory?.totalAmount ?? 0,
        categoryBreakdown: categoryBreakdown,
        memberBreakdown: memberBreakdown,
      );
    });
  }

  @override
  Future<GroupBudget> fetchBudget(String groupId) {
    if (_useMockData) {
      return _mock.fetchBudget(groupId);
    }
    return _guard('fetch group budget', () async {
      return GroupModelMapper.budget(await _remote.fetchBudget(groupId));
    });
  }

  @override
  Future<void> updateBudget(GroupBudget budget) {
    if (_useMockData) {
      return _mock.updateBudget(budget);
    }
    return _guard('update group budget', () => _remote.updateBudget(budget));
  }

  @override
  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) async {
    final overview = await fetchSettlementOverview(groupId);
    final result =
        overview.suggestions
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
            .toList()
          ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return result;
  }

  @override
  Future<String> buildGroupReportCsv(String groupId) async {
    final detail = await fetchGroupDetail(groupId);
    final transactions = await fetchTransactions(groupId);
    final settlement = await fetchSettlementOverview(groupId);
    final history = await fetchSettlementHistory(groupId);
    final buffer = StringBuffer()
      ..writeln(_csvRow(['Bao cao nhom', detail.group.name]))
      ..writeln()
      ..writeln(_csvRow(['Giao dich']))
      ..writeln(_csvRow(['Ngay', 'Nguoi tao', 'Danh muc', 'Mo ta', 'So tien']));
    for (final transaction in transactions) {
      buffer.writeln(
        _csvRow([
          transaction.transactionDate.toIso8601String(),
          transaction.creatorName ?? transaction.createdBy,
          transaction.categoryName ?? '',
          transaction.caption ?? transaction.note ?? '',
          transaction.totalAmount.toString(),
        ]),
      );
    }
    buffer
      ..writeln()
      ..writeln(_csvRow(['Can doi']))
      ..writeln(_csvRow(['Thanh vien', 'Da tra', 'Phai chiu', 'Can doi']));
    for (final balance in settlement.balances) {
      buffer.writeln(
        _csvRow([
          balance.displayName ?? balance.userId,
          balance.totalPaidAmount.toString(),
          balance.totalShareAmount.toString(),
          balance.balance.toString(),
        ]),
      );
    }
    buffer
      ..writeln()
      ..writeln(_csvRow(['Lich su thanh toan no']))
      ..writeln(_csvRow(['Cap thanh toan', 'So tien', 'Trang thai', 'Ngay']));
    for (final entry in history) {
      buffer.writeln(
        _csvRow([
          '${entry.fromName} -> ${entry.toName}',
          entry.amount.toString(),
          entry.status,
          entry.updatedAt.toIso8601String(),
        ]),
      );
    }
    return buffer.toString();
  }

  @override
  Future<List<GroupFeedItem>> fetchFeed(String groupId) async {
    final transactions = await fetchTransactions(groupId);
    final items = <GroupFeedItem>[];
    for (final transaction in transactions) {
      final detail = await fetchTransactionDetail(transaction.id);
      items.add(
        GroupFeedItem(
          transaction: transaction,
          reactions: await fetchReactionSummaries(transaction.id),
          commentCount: detail.comments.length,
        ),
      );
    }
    return items;
  }

  @override
  Future<List<GroupPhotoItem>> fetchPhotoAlbum(String groupId) async {
    final transactions = await fetchTransactions(groupId);
    return transactions
        .where((item) => item.imagePath?.isNotEmpty == true)
        .map(
          (item) => GroupPhotoItem(
            transactionId: item.id,
            groupId: item.groupId,
            createdBy: item.createdBy,
            caption: item.caption ?? item.categoryName,
            imagePath: item.imagePath!,
            amount: item.totalAmount,
            transactionDate: item.transactionDate,
            creatorName: item.creatorName,
          ),
        )
        .toList();
  }

  @override
  Future<GroupPublicProfile> fetchPublicProfile(String groupId) {
    if (_useMockData) {
      return _mock.fetchPublicProfile(groupId);
    }
    return _guard('fetch group public profile', () async {
      return GroupModelMapper.publicProfile(
        await _remote.fetchPublicProfile(groupId),
      );
    });
  }

  @override
  Future<void> updatePublicProfile(GroupPublicProfile profile) {
    if (_useMockData) {
      return _mock.updatePublicProfile(profile);
    }
    return _guard(
      'update group public profile',
      () => _remote.updatePublicProfile(profile),
    );
  }

  @override
  Future<void> markSettlementPaid(String settlementId) {
    if (_useMockData) {
      return _mock.markSettlementPaid(settlementId);
    }
    return _guard(
      'mark group settlement paid',
      () => _remote.markSettlementPaid(settlementId),
    );
  }

  @override
  Future<void> confirmSettlementReceived(String settlementId) {
    if (_useMockData) {
      return _mock.confirmSettlementReceived(settlementId);
    }
    return _guard(
      'confirm group settlement received',
      () => _remote.confirmSettlementReceived(settlementId),
    );
  }

  @override
  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  }) {
    if (_useMockData) {
      return _mock.disputeSettlement(
        settlementId: settlementId,
        reason: reason,
      );
    }
    return _guard(
      'dispute group settlement',
      () =>
          _remote.disputeSettlement(settlementId: settlementId, reason: reason),
    );
  }

  @override
  Future<void> resetDisputedSettlement(String settlementId) {
    if (_useMockData) {
      return _mock.resetDisputedSettlement(settlementId);
    }
    return _guard(
      'reset disputed group settlement',
      () => _remote.resetDisputedSettlement(settlementId),
    );
  }

  @override
  Future<void> removeMember({required String groupId, required String userId}) {
    if (_useMockData) {
      return _mock.removeMember(groupId: groupId, userId: userId);
    }
    return _guard(
      'remove group member',
      () => _remote.removeMember(groupId: groupId, userId: userId),
    );
  }

  @override
  Future<void> leaveGroup(String groupId) {
    if (_useMockData) {
      return _mock.leaveGroup(groupId);
    }
    return _guard('leave group', () => _remote.leaveGroup(groupId));
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) {
    if (_useMockData) {
      return _mock.transferOwnership(
        groupId: groupId,
        newOwnerUserId: newOwnerUserId,
      );
    }
    return _guard(
      'transfer group ownership',
      () => _remote.transferOwnership(
        groupId: groupId,
        newOwnerUserId: newOwnerUserId,
      ),
    );
  }

  @override
  Future<void> addComment({
    required String transactionId,
    required String content,
  }) {
    if (_useMockData) {
      return _mock.addComment(transactionId: transactionId, content: content);
    }
    return _guard(
      'add group transaction comment',
      () => _remote.addComment(transactionId: transactionId, content: content),
    );
  }

  @override
  Future<List<GroupReactionSummary>> fetchReactions(String transactionId) {
    if (_useMockData) {
      return _mock.fetchReactions(transactionId);
    }
    return _guard('fetch group transaction reactions', () async {
      final rows = await _remote.fetchReactions(transactionId);
      return rows.map(GroupModelMapper.reaction).toList();
    });
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String transactionId,
    required String content,
  }) {
    if (_useMockData) {
      return _mock.updateComment(
        commentId: commentId,
        transactionId: transactionId,
        content: content,
      );
    }
    return _guard(
      'update group transaction comment',
      () => _remote.updateComment(commentId: commentId, content: content),
    );
  }

  @override
  Future<void> deleteComment({
    required String commentId,
    required String transactionId,
  }) {
    if (_useMockData) {
      return _mock.deleteComment(
        commentId: commentId,
        transactionId: transactionId,
      );
    }
    return _guard(
      'delete group transaction comment',
      () => _remote.deleteComment(commentId),
    );
  }

  @override
  Future<GroupPublicProfile> fetchPublicGroupProfile(String slug) {
    if (_useMockData) {
      return Future.error(
        const AppException('Public profile unavailable in demo mode'),
      );
    }
    return _guard('fetch public group profile', () async {
      final row = await _remote.fetchPublicGroupProfile(slug);
      if (row == null) {
        throw const AppException(
          'Public group profile not found',
          code: 'NOT_FOUND',
        );
      }
      return _publicProfileFromRow(row, groupId: row['group_id'] as String);
    });
  }

  GroupPublicProfile _publicProfileFromRow(
    Map<String, dynamic> row, {
    required String groupId,
  }) {
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: row['is_enabled'] as bool? ?? true,
      showStats: row['show_stats'] as bool? ?? false,
      slug: row['slug'] as String?,
      groupName: row['group_name'] as String?,
      avatarPath: row['avatar_path'] as String?,
      description: row['description'] as String?,
      groupType: row['group_type'] as String?,
      memberCount: (row['member_count'] as num?)?.toInt(),
      transactionCount: (row['transaction_count'] as num?)?.toInt(),
      totalSpent: (row['total_spent'] as num?)?.toInt(),
    );
  }

  @override
  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) async {
    if (_useMockData) return const [];
    return _guard('fetch recurring group transactions', () async {
      final rows = await _remote.fetchRecurringTransactions(groupId);
      return rows.map(_recurringFromRow).toList(growable: false);
    });
  }

  @override
  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  }) {
    if (_useMockData) return Future.value('mock-recurring-id');
    return _guard(
      'create recurring group transaction',
      () => _remote.createRecurringTransaction(
        groupId: groupId,
        title: title,
        amount: amount,
        frequency: frequency,
        nextRunAt: nextRunAt,
        notifyDaysBefore: notifyDaysBefore,
      ),
    );
  }

  @override
  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
  }) {
    if (_useMockData) return Future.value();
    return _guard(
      'update recurring group transaction',
      () => _remote.updateRecurringTransaction(
        id: id,
        title: title,
        amount: amount,
        frequency: frequency,
        nextRunAt: nextRunAt,
        notifyDaysBefore: notifyDaysBefore,
        isActive: isActive,
      ),
    );
  }

  @override
  Future<void> deleteRecurringTransaction(String id) {
    if (_useMockData) return Future.value();
    return _guard(
      'delete recurring group transaction',
      () => _remote.deleteRecurringTransaction(id),
    );
  }

  GroupRecurringTransaction _recurringFromRow(Map<String, dynamic> row) {
    return GroupRecurringTransaction(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      createdBy: row['created_by'] as String,
      title: row['title'] as String,
      amount: (row['amount'] as num).toInt(),
      frequency: row['frequency'] as String,
      nextRunAt: DateTime.parse(row['next_run_at'] as String),
      notifyDaysBefore: (row['notify_days_before'] as num).toInt(),
      isActive: row['is_active'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(operation, error, stackTrace);
      if (error.message.startsWith('GROUP_') ||
          error.message == 'AUTH_REQUIRED' ||
          error.message == 'NOT_FOUND') {
        throw AppException(error.message, code: error.message);
      }
      throw AppException(error.message, code: error.code);
    } on StorageException catch (error, stackTrace) {
      AppLogger.error(operation, error, stackTrace);
      throw AppException(error.message, code: error.statusCode);
    } catch (error, stackTrace) {
      if (error is AppException) {
        rethrow;
      }
      AppLogger.error(operation, error, stackTrace);
      throw const AppException('errorConnection');
    }
  }

  static GroupStatsOverview _buildStats({
    required SpendingGroupDetail detail,
    required List<GroupTransaction> transactions,
    required GroupSettlementOverview settlement,
    required String currentUserId,
  }) {
    final posted = transactions.where(
      (item) => item.splitStatus == GroupSplitStatus.posted,
    );
    final pendingTransactions = transactions.where(
      (item) =>
          item.splitStatus != GroupSplitStatus.posted &&
          item.splitStatus != GroupSplitStatus.cancelled,
    );
    final pendingSettlements = settlement.suggestions.where(
      (item) => item.status != GroupSettlementStatus.completed,
    );
    final ownBalance = settlement.balances
        .where((item) => item.userId == currentUserId)
        .fold<int>(0, (sum, item) => sum + item.balance);
    return GroupStatsOverview(
      totalSpent: posted.fold<int>(
        0,
        (sum, transaction) => sum + transaction.totalAmount,
      ),
      transactionCount: transactions.length,
      pendingTransactionCount: pendingTransactions.length,
      pendingSettlementCount: pendingSettlements.length,
      memberCount: detail.activeMembers.length,
      currentUserBalance: ownBalance,
    );
  }

  static String _csvRow(List<String> values) {
    return values
        .map((value) {
          final escaped = value.replaceAll('"', '""');
          return '"$escaped"';
        })
        .join(',');
  }
}

class _MemberStats {
  _MemberStats(this.displayName);

  final String displayName;
  int shareAmount = 0;
  int paidAmount = 0;
  int transactionCount = 0;
}
