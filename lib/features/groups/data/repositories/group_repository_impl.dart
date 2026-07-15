import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
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
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) {
    if (_useMockData) {
      return _mock.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        type: type,
      );
    }
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
    if (_useMockData) {
      return _mock.setGroupArchived(groupId: groupId, archived: archived);
    }
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
    if (_useMockData) {
      return _mock.updateGroupAvatar(groupId: groupId, filePath: filePath);
    }
    return _guard('update group avatar', () async {
      await _remote.uploadGroupAvatar(groupId: groupId, filePath: filePath);
    });
  }

  @override
  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) {
    if (_useMockData) {
      return _mock.updateGroupCurrency(
        groupId: groupId,
        baseCurrency: baseCurrency,
      );
    }
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
  Future<GroupTransactionPage> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async {
    if (_useMockData) {
      final rows = await _mock.fetchTransactionsPage(
        groupId: groupId,
        offset: offset,
        limit: limit,
        query: query,
        status: status,
      );
      return GroupTransactionPage(
        items: rows.take(limit).toList(growable: false),
        hasMore: rows.length > limit,
      );
    }
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
  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) async {
    if (_useMockData) {
      return _mock.fetchMonthlyStats(groupId: groupId, month: month);
    }
    return _guard('fetch group monthly stats', () async {
      final row = await _remote.fetchMonthlyStats(
        groupId: groupId,
        month: month,
      );
      return _monthlyStatsFromRow(row, groupId: groupId);
    });
  }

  @override
  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) async {
    if (_useMockData) return _mock.fetchSettlementHistory(groupId);
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
  Future<List<GroupActivity>> fetchActivities(String groupId) {
    if (_useMockData) {
      return _mock.fetchActivities(groupId);
    }
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
    if (_useMockData) {
      return _mock.fetchCommunityPosts(
        groupId: groupId,
        offset: offset,
        limit: limit,
      );
    }
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
    if (_useMockData) {
      return _mock.createCommunityPost(
        groupId: groupId,
        type: type,
        content: content,
        media: media,
      );
    }
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
  Future<void> addCommunityPostComment({
    required String postId,
    required String content,
  }) {
    if (_useMockData) {
      return _mock.addCommunityPostComment(postId: postId, content: content);
    }
    return _guard(
      'add group community comment',
      () => _remote.addCommunityPostComment(postId: postId, content: content),
    );
  }

  @override
  Future<void> toggleCommunityPostReaction({
    required String postId,
    required String emoji,
  }) {
    if (_useMockData) {
      return _mock.toggleCommunityPostReaction(postId: postId, emoji: emoji);
    }
    return _guard(
      'toggle group community reaction',
      () => _remote.toggleCommunityPostReaction(postId: postId, emoji: emoji),
    );
  }

  @override
  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId) {
    if (_useMockData) return _mock.fetchAuditLogs(groupId);
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
    if (_useMockData) return _mock.fetchPolls(groupId);
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
            return GroupPoll(
              id: row['id'] as String,
              groupId: row['group_id'] as String,
              title: row['title'] as String,
              options: options,
              isClosed: row['is_closed'] as bool? ?? false,
              createdAt: DateTime.parse(row['created_at'] as String),
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
    if (_useMockData) {
      return _mock.createPoll(groupId: groupId, title: title, options: options);
    }
    return _guard(
      'create group poll',
      () =>
          _remote.createPoll(groupId: groupId, title: title, options: options),
    );
  }

  @override
  Future<void> votePoll({required String pollId, required String optionId}) {
    if (_useMockData) return _mock.votePoll(pollId: pollId, optionId: optionId);
    return _guard(
      'vote in group poll',
      () => _remote.votePoll(pollId: pollId, optionId: optionId),
    );
  }

  @override
  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(
    String groupId,
  ) async {
    if (_useMockData) return _mock.fetchSavingsChallenges(groupId);
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
    if (_useMockData) {
      return _mock.createSavingsChallenge(
        groupId: groupId,
        title: title,
        targetAmount: targetAmount,
        startDate: startDate,
        endDate: endDate,
      );
    }
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
    if (_useMockData) {
      return _mock.addSavingsContribution(
        challengeId: challengeId,
        amount: amount,
        note: note,
      );
    }
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
    if (_useMockData) {
      return _mock.fetchNotifications(category: category);
    }
    return _guard('fetch group notifications', () async {
      final rows = await _remote.fetchNotifications(category: category);
      return rows.map(GroupModelMapper.notification).toList();
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
  Future<void> markAllNotificationsRead() {
    if (_useMockData) return _mock.markAllNotificationsRead();
    return _guard(
      'mark all group notifications read',
      _remote.markAllNotificationsRead,
    );
  }

  @override
  Future<GroupBudget> fetchBudget(String groupId) async {
    if (_useMockData) return GroupBudget.defaults(groupId);
    return _guard('fetch group budget', () async {
      final row = await _remote.fetchBudget(groupId);
      if (row == null) return GroupBudget.defaults(groupId);
      return GroupBudget(
        groupId: groupId,
        monthlyLimit: (row['monthly_limit'] as num).toInt(),
        warningThresholdPercent: (row['warning_threshold_percent'] as num)
            .toInt(),
      );
    });
  }

  @override
  Future<void> saveBudget(GroupBudget budget) {
    if (_useMockData) return Future.value();
    return _guard('save group budget', () => _remote.saveBudget(budget));
  }

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) async {
    if (_useMockData) return GroupNotificationPreference.defaults(groupId);
    return _guard('fetch group notification preference', () async {
      final row = await _remote.fetchNotificationPreference(
        groupId: groupId,
        userId: currentUserId,
      );
      if (row == null) return GroupNotificationPreference.defaults(groupId);
      return GroupNotificationPreference(
        groupId: groupId,
        muteAll: row['mute_all'] as bool,
        transactionNotifications: row['transaction_notifications'] as bool,
        debtNotifications: row['debt_notifications'] as bool,
        inviteNotifications: row['invite_notifications'] as bool,
        mentionNotifications: row['mention_notifications'] as bool,
        communityComments: row['community_comments'] as bool? ?? true,
        communityReactions: row['community_reactions'] as bool? ?? true,
        quietHoursStart: (row['quiet_hours_start'] as num?)?.toInt(),
        quietHoursEnd: (row['quiet_hours_end'] as num?)?.toInt(),
      );
    });
  }

  @override
  Future<void> saveNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    if (_useMockData) return Future.value();
    return _guard(
      'save group notification preference',
      () => _remote.saveNotificationPreference(
        groupId: preference.groupId,
        userId: currentUserId,
        preference: preference,
      ),
    );
  }

  @override
  Future<GroupPublicProfile> fetchGroupPublicProfile(String groupId) async {
    if (_useMockData) return GroupPublicProfile.defaults(groupId);
    return _guard('fetch group public profile', () async {
      final row = await _remote.fetchGroupPublicProfile(groupId);
      if (row == null) return GroupPublicProfile.defaults(groupId);
      return _publicProfileFromRow(row, groupId: groupId);
    });
  }

  @override
  Future<void> saveGroupPublicProfile(GroupPublicProfile profile) {
    if (_useMockData) return Future.value();
    return _guard(
      'save group public profile',
      () => _remote.saveGroupPublicProfile(profile),
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
    bool autoPost = false,
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
        autoPost: autoPost,
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
}
