import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../shared/utils/app_logger.dart';
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
  Future<GroupBudget?> fetchGroupBudget(String groupId) {
    if (_useMockData) {
      return _mock.fetchGroupBudget(groupId).then((row) {
        if (row == null) return null;
        return GroupBudget(
          groupId: row['group_id'] as String,
          monthlyLimit: (row['monthly_limit'] as num).toInt(),
          warningThresholdPercent:
              (row['warning_threshold_percent'] as num).toInt(),
        );
      });
    }
    return _guard('fetch group budget', () async {
      final row = await _remote.fetchGroupBudget(groupId);
      if (row == null) return null;
      return GroupBudget(
        groupId: row['group_id'] as String,
        monthlyLimit: (row['monthly_limit'] as num).toInt(),
        warningThresholdPercent:
            (row['warning_threshold_percent'] as num).toInt(),
      );
    });
  }

  @override
  Future<void> upsertGroupBudget({
    required String groupId,
    required int monthlyLimit,
    required int warningThresholdPercent,
  }) {
    if (_useMockData) {
      return _mock.upsertGroupBudget(
        groupId: groupId,
        monthlyLimit: monthlyLimit,
        warningThresholdPercent: warningThresholdPercent,
      );
    }
    return _guard(
      'upsert group budget',
      () => _remote.upsertGroupBudget(
        groupId: groupId,
        monthlyLimit: monthlyLimit,
        warningThresholdPercent: warningThresholdPercent,
      ),
    );
  }

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) {
    if (_useMockData) {
      return _mock
          .fetchNotificationPreference(groupId)
          .then((row) => _mapNotificationPreference(groupId, row));
    }
    return _guard('fetch group notification preference', () async {
      final row = await _remote.fetchNotificationPreference(groupId);
      return _mapNotificationPreference(groupId, row);
    });
  }

  @override
  Future<void> upsertNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    if (_useMockData) {
      return _mock.upsertNotificationPreference(
        groupId: preference.groupId,
        muteAll: preference.muteAll,
        transactionNotifications: preference.transactionNotifications,
        debtNotifications: preference.debtNotifications,
        inviteNotifications: preference.inviteNotifications,
        mentionNotifications: preference.mentionNotifications,
        quietHoursStart: preference.quietHoursStart,
        quietHoursEnd: preference.quietHoursEnd,
      );
    }
    return _guard(
      'upsert group notification preference',
      () => _remote.upsertNotificationPreference(
        groupId: preference.groupId,
        muteAll: preference.muteAll,
        transactionNotifications: preference.transactionNotifications,
        debtNotifications: preference.debtNotifications,
        inviteNotifications: preference.inviteNotifications,
        mentionNotifications: preference.mentionNotifications,
        quietHoursStart: preference.quietHoursStart,
        quietHoursEnd: preference.quietHoursEnd,
      ),
    );
  }

  GroupNotificationPreference _mapNotificationPreference(
    String groupId,
    Map<String, dynamic>? row,
  ) {
    if (row == null) {
      return GroupNotificationPreference.defaults(groupId);
    }
    return GroupNotificationPreference(
      groupId: groupId,
      muteAll: row['mute_all'] as bool? ?? false,
      transactionNotifications:
          row['transaction_notifications'] as bool? ?? true,
      debtNotifications: row['debt_notifications'] as bool? ?? true,
      inviteNotifications: row['invite_notifications'] as bool? ?? true,
      mentionNotifications: row['mention_notifications'] as bool? ?? true,
      quietHoursStart: (row['quiet_hours_start'] as num?)?.toInt(),
      quietHoursEnd: (row['quiet_hours_end'] as num?)?.toInt(),
    );
  }

  @override
  Future<GroupPublicProfile> fetchPublicProfile(String groupId) {
    if (_useMockData) {
      return _mock
          .fetchPublicProfile(groupId)
          .then((row) => _mapPublicProfile(groupId, row));
    }
    return _guard('fetch group public profile', () async {
      final row = await _remote.fetchPublicProfile(groupId);
      return _mapPublicProfile(groupId, row);
    });
  }

  @override
  Future<void> upsertPublicProfile(GroupPublicProfile profile) {
    if (_useMockData) {
      return _mock.upsertPublicProfile(
        groupId: profile.groupId,
        isEnabled: profile.isEnabled,
        showStats: profile.showStats,
        slug: profile.slug,
      );
    }
    return _guard(
      'upsert group public profile',
      () => _remote.upsertPublicProfile(
        groupId: profile.groupId,
        isEnabled: profile.isEnabled,
        showStats: profile.showStats,
        slug: profile.slug,
      ),
    );
  }

  GroupPublicProfile _mapPublicProfile(
    String groupId,
    Map<String, dynamic>? row,
  ) {
    if (row == null) {
      return GroupPublicProfile.defaults(groupId);
    }
    return GroupPublicProfile(
      groupId: groupId,
      isEnabled: row['is_enabled'] as bool? ?? false,
      showStats: row['show_stats'] as bool? ?? false,
      slug: row['slug'] as String?,
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
