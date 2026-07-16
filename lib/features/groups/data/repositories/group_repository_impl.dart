import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../domain/entities/group_community.dart';
import '../../domain/entities/group_community_feed.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/spending_group.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_supabase_data_source.dart';
import '../models/group_model_mapper.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  ref.watch(currentSessionProvider);
  final client = ref.watch(supabaseClientProvider);
  return GroupRepositoryImpl(client);
});

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(SupabaseClient client)
    : _client = client,
      _remote = GroupSupabaseDataSource(client);

  final SupabaseClient _client;
  final GroupSupabaseDataSource _remote;

  @override
  String get currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('User not logged in', code: 'AUTH_REQUIRED');
    }
    return userId;
  }

  @override
  Future<List<SpendingGroup>> fetchGroups() async {
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
                  item['status'] == 'payer_marked_paid' ||
                  item['status'] == 'disputed',
            ),
          ),
        );
      }
      return result;
    });
  }

  @override
  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) async {
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
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) {
    return _guard(
      'update group details',
      () => _remote.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        type: type,
      ),
    );
  }

  @override
  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) {
    return _guard(
      'update group archive status',
      () => _remote.setGroupArchived(groupId: groupId, archived: archived),
    );
  }

  @override
  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  }) {
    return _guard('update group avatar', () async {
      await _remote.uploadGroupAvatar(groupId: groupId, filePath: filePath);
    });
  }

  @override
  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) {
    return _guard(
      'update group base currency',
      () => _remote.updateGroupCurrency(
        groupId: groupId,
        baseCurrency: baseCurrency,
      ),
    );
  }

  @override
  Future<String> createInviteLink(String groupId) {
    return _guard(
      'create group invite link',
      () => _remote.createInviteLink(groupId),
    );
  }

  @override
  Future<GroupInvitePreview> fetchInvitePreview(String token) {
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
    return _guard(
      'revoke group invite link',
      () => _remote.revokeInviteLink(token.trim()),
    );
  }

  @override
  Future<List<GroupDirectInvite>> fetchDirectInvites() {
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
    return _guard(
      'decline direct group invite',
      () => _remote.declineDirectInvite(inviteId),
    );
  }

  @override
  Future<void> declineInvite(String token) {
    return _guard('decline group invite', () => _remote.declineInvite(token));
  }

  @override
  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) {
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
    return _guard(
      'invite group member by user id',
      () => _remote.inviteByUserId(groupId: groupId, userId: userId),
    );
  }

  @override
  Future<List<GroupTransaction>> fetchTransactions(String groupId) {
    return _guard('fetch group transactions', () async {
      return (await _remote.fetchTransactions(
        groupId,
      )).map(GroupModelMapper.transaction).toList();
    });
  }

  @override
  Future<GroupTransactionPage> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async {
    return _guard('fetch group transactions page', () async {
      final rows = await _remote.fetchTransactionsPage(
        groupId: groupId,
        offset: offset,
        limit: limit,
        query: query,
        status: status,
      );
      final items = rows
          .map(GroupModelMapper.transaction)
          .toList(growable: false);
      return GroupTransactionPage(
        items: items.take(limit).toList(growable: false),
        hasMore: items.length > limit,
      );
    });
  }

  @override
  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId) {
    return _guard('fetch group transaction detail', () async {
      final transactionRow = await _remote.fetchTransaction(transactionId);
      final groupId = transactionRow['group_id'] as String;
      final settlements = await _remote.fetchSettlements(groupId);
      transactionRow['has_completed_settlement'] = settlements.any(
        (item) => item['status'] == 'completed',
      );
      transactionRow['has_settlement_lock'] = settlements.any(
        (item) => item['status'] != 'pending',
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
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) {
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
    return _guard(
      'update group notification preference',
      () => _remote.updateNotificationPreference(preference),
    );
  }

  @override
  Future<List<GroupReactionSummary>> fetchReactionSummaries(
    String transactionId,
  ) {
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
    return _guard(
      'toggle group transaction reaction',
      () => _remote.toggleReaction(transactionId: transactionId, emoji: emoji),
    );
  }

  @override
  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) async {
    return _guard('fetch group monthly stats', () async {
      final row = await _remote.fetchMonthlyStats(
        groupId: groupId,
        month: month,
      );
      return _monthlyStatsFromRow(row, groupId: groupId);
    });
  }

  @override
  Future<GroupBudget> fetchBudget(String groupId) {
    return _guard('fetch group budget', () async {
      return GroupModelMapper.budget(await _remote.fetchBudget(groupId));
    });
  }

  @override
  Future<void> updateBudget(GroupBudget budget) {
    return _guard('update group budget', () => _remote.updateBudget(budget));
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
    return _guard('fetch group public profile', () async {
      return GroupModelMapper.publicProfile(
        await _remote.fetchPublicProfile(groupId),
      );
    });
  }

  @override
  Future<void> updatePublicProfile(GroupPublicProfile profile) {
    return _guard(
      'update group public profile',
      () => _remote.updatePublicProfile(profile),
    );
  }

  @override
  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) async {
    return _guard('fetch group settlement history', () async {
      final rows = await _remote.fetchSettlementHistory(groupId);
      return rows
          .map(
            (row) => GroupSettlementHistoryEntry(
              id: row['id'] as String,
              fromName: row['from_name'] as String? ?? '',
              toName: row['to_name'] as String? ?? '',
              amount: (row['amount'] as num).toInt(),
              status: row['status'] as String,
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> markSettlementPaid(String settlementId) {
    return _guard(
      'mark group settlement paid',
      () => _remote.markSettlementPaid(settlementId),
    );
  }

  @override
  Future<void> confirmSettlementReceived(String settlementId) {
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
    return _guard(
      'dispute group settlement',
      () =>
          _remote.disputeSettlement(settlementId: settlementId, reason: reason),
    );
  }

  @override
  Future<void> resetDisputedSettlement(String settlementId) {
    return _guard(
      'reset disputed group settlement',
      () => _remote.resetDisputedSettlement(settlementId),
    );
  }

  @override
  Future<void> removeMember({required String groupId, required String userId}) {
    return _guard(
      'remove group member',
      () => _remote.removeMember(groupId: groupId, userId: userId),
    );
  }

  @override
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) {
    return _guard(
      'update group member role',
      () => _remote.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      ),
    );
  }

  @override
  Future<void> leaveGroup(String groupId) {
    return _guard('leave group', () => _remote.leaveGroup(groupId));
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) {
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
    return _guard(
      'add group transaction comment',
      () => _remote.addComment(transactionId: transactionId, content: content),
    );
  }

  @override
  Future<List<GroupReactionSummary>> fetchReactions(String transactionId) {
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
    return _guard(
      'delete group transaction comment',
      () => _remote.deleteComment(commentId),
    );
  }

  @override
  Future<List<GroupActivity>> fetchActivities(String groupId) {
    return _guard('fetch group activities', () async {
      final rows = await _remote.fetchActivities(groupId);
      return rows.map(GroupModelMapper.activity).toList();
    });
  }

  @override
  Future<List<GroupCommunityPost>> fetchCommunityPosts({
    required String groupId,
    int offset = 0,
    int limit = 30,
  }) {
    return _guard('fetch group community posts', () async {
      final rows = await _remote.fetchCommunityPosts(
        groupId: groupId,
        offset: offset,
        limit: limit,
      );
      return rows
          .map(
            (row) => GroupModelMapper.communityPost(
              row,
              currentUserId: currentUserId,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<String> createCommunityPost({
    required String groupId,
    required String type,
    String? content,
    List<GroupCommunityMediaDraft> media = const [],
  }) {
    return _guard('create group community post', () async {
      final postId = await _remote.createCommunityPost(
        groupId: groupId,
        type: type,
        content: content,
      );
      for (final item in media) {
        final mediaId = await _remote.createCommunityMedia(
          groupId: groupId,
          postId: postId,
          kind: item.kind,
          caption: item.caption,
        );
        try {
          await _remote.uploadCommunityMedia(
            groupId: groupId,
            mediaId: mediaId,
            filePath: item.localPath,
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'Group community media upload failed',
            error,
            stackTrace,
          );
          rethrow;
        }
      }
      return postId;
    });
  }

  @override
  Future<void> updateCommunityPost({
    required String postId,
    required String content,
  }) {
    return _guard(
      'update group community post',
      () => _remote.updateCommunityPost(postId: postId, content: content),
    );
  }

  @override
  Future<void> deleteCommunityPost(String postId) {
    return _guard(
      'delete group community post',
      () => _remote.deleteCommunityPost(postId),
    );
  }

  @override
  Future<void> addCommunityPostComment({
    required String postId,
    required String content,
  }) {
    return _guard(
      'add group community comment',
      () => _remote.addCommunityPostComment(postId: postId, content: content),
    );
  }

  @override
  Future<void> updateCommunityPostComment({
    required String commentId,
    required String content,
  }) {
    return _guard(
      'update group community post comment',
      () => _remote.updateCommunityPostComment(
        commentId: commentId,
        content: content,
      ),
    );
  }

  @override
  Future<void> deleteCommunityPostComment(String commentId) {
    return _guard(
      'delete group community post comment',
      () => _remote.deleteCommunityPostComment(commentId),
    );
  }

  @override
  Future<void> toggleCommunityPostReaction({
    required String postId,
    required String emoji,
  }) {
    return _guard(
      'toggle group community reaction',
      () => _remote.toggleCommunityPostReaction(postId: postId, emoji: emoji),
    );
  }

  @override
  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId) {
    return _guard('fetch group audit logs', () async {
      final rows = await _remote.fetchAuditLogs(groupId);
      return rows
          .map(
            (row) => GroupAuditLog(
              id: row['id'] as String,
              groupId: row['group_id'] as String,
              actorUserId: row['actor_user_id'] as String?,
              action: row['action'] as String,
              targetUserId: row['target_user_id'] as String?,
              targetTransactionId: row['target_transaction_id'] as String?,
              metadata: Map<String, dynamic>.from(
                row['metadata'] as Map? ?? const {},
              ),
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<List<GroupPoll>> fetchPolls(String groupId) async {
    return _guard('fetch group polls', () async {
      final rows = await _remote.fetchPolls(groupId);
      return rows
          .map((row) {
            final options = (row['options'] as List? ?? const [])
                .map((item) => Map<String, dynamic>.from(item as Map))
                .map(
                  (item) => GroupPollOption(
                    id: item['id'] as String,
                    label: item['label'] as String,
                    voteCount: (item['vote_count'] as num?)?.toInt() ?? 0,
                  ),
                )
                .toList(growable: false);
            final votes = (row['votes'] as List? ?? const []).map(
              (item) => Map<String, dynamic>.from(item as Map),
            );
            String? selectedOptionId;
            for (final vote in votes) {
              if (vote['user_id'] == currentUserId) {
                selectedOptionId = vote['option_id'] as String?;
                break;
              }
            }
            return GroupPoll(
              id: row['id'] as String,
              groupId: row['group_id'] as String,
              title: row['title'] as String,
              options: options,
              isClosed: row['is_closed'] as bool? ?? false,
              createdAt: DateTime.parse(row['created_at'] as String),
              selectedOptionId: selectedOptionId,
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) {
    return _guard(
      'create group poll',
      () =>
          _remote.createPoll(groupId: groupId, title: title, options: options),
    );
  }

  @override
  Future<void> votePoll({required String pollId, required String optionId}) {
    return _guard(
      'vote in group poll',
      () => _remote.votePoll(pollId: pollId, optionId: optionId),
    );
  }

  @override
  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(
    String groupId,
  ) async {
    return _guard('fetch savings challenges', () async {
      final rows = await _remote.fetchSavingsChallenges(groupId);
      return rows
          .map((row) {
            final contributions = row['contributions'] as List? ?? const [];
            final total = contributions.fold<int>(
              0,
              (sum, item) => sum + ((item as Map)['amount'] as num).toInt(),
            );
            return GroupSavingsChallenge(
              id: row['id'] as String,
              groupId: row['group_id'] as String,
              title: row['title'] as String,
              targetAmount: (row['target_amount'] as num).toInt(),
              startDate: DateTime.parse(row['start_date'] as String),
              endDate: DateTime.parse(row['end_date'] as String),
              totalContributed: total,
              isActive: row['is_active'] as bool? ?? true,
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _guard(
      'create savings challenge',
      () => _remote.createSavingsChallenge(
        groupId: groupId,
        title: title,
        targetAmount: targetAmount,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  }) {
    return _guard(
      'add savings contribution',
      () => _remote.addSavingsContribution(
        challengeId: challengeId,
        amount: amount,
        note: note,
      ),
    );
  }

  @override
  Future<List<GroupNotification>> fetchNotifications({String? category}) {
    return _guard('fetch group notifications', () async {
      final rows = await _remote.fetchNotifications(category: category);
      return rows.map(GroupModelMapper.notification).toList();
    });
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    return _guard(
      'mark group notification read',
      () => _remote.markNotificationRead(notificationId),
    );
  }

  @override
  Future<void> markAllNotificationsRead() {
    return _guard(
      'mark all group notifications read',
      _remote.markAllNotificationsRead,
    );
  }

  @override
  Future<GroupPublicProfile> fetchPublicGroupProfile(String slug) {
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
      showDescription: row['show_description'] as bool? ?? false,
      showGroupType: row['show_group_type'] as bool? ?? false,
      showAvatar: row['show_avatar'] as bool? ?? false,
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

  GroupMonthlyStats _monthlyStatsFromRow(
    Map<String, dynamic> row, {
    required String groupId,
  }) {
    final categories = _jsonList(row['category_breakdown']);
    final members = _jsonList(row['member_breakdown']);
    return GroupMonthlyStats(
      groupId: groupId,
      month: DateTime.parse(row['month'] as String),
      totalSpent: (row['total_spent'] as num?)?.toInt() ?? 0,
      transactionCount: (row['transaction_count'] as num?)?.toInt() ?? 0,
      topCategoryName: row['top_category_name'] as String?,
      topCategoryAmount: (row['top_category_amount'] as num?)?.toInt() ?? 0,
      categoryBreakdown: categories
          .map(
            (item) => GroupCategorySpending(
              categoryName: item['category_name'] as String,
              totalAmount: (item['total_amount'] as num).toInt(),
              transactionCount: (item['transaction_count'] as num).toInt(),
            ),
          )
          .toList(growable: false),
      memberBreakdown: members
          .map(
            (item) => GroupMemberBreakdown(
              userId: item['user_id'] as String,
              displayName: item['display_name'] as String? ?? '',
              shareAmount: (item['share_amount'] as num).toInt(),
              paidAmount: (item['paid_amount'] as num).toInt(),
              balance: (item['balance'] as num).toInt(),
              transactionCount: (item['transaction_count'] as num).toInt(),
            ),
          )
          .toList(growable: false),
    );
  }

  List<Map<String, dynamic>> _jsonList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) async {
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
    bool autoPost = false,
  }) {
    return _guard(
      'create recurring group transaction',
      () => _remote.createRecurringTransaction(
        groupId: groupId,
        title: title,
        amount: amount,
        frequency: frequency,
        nextRunAt: nextRunAt,
        notifyDaysBefore: notifyDaysBefore,
        autoPost: autoPost,
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
    bool autoPost = false,
  }) {
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
        autoPost: autoPost,
      ),
    );
  }

  @override
  Future<void> deleteRecurringTransaction(String id) {
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
      autoPost: row['auto_post'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error(operation, error, stackTrace);
      if (error.message.startsWith('GROUP_') ||
          error.message.startsWith('CHALLENGE_') ||
          error.message.startsWith('POLL_') ||
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
