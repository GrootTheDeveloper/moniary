import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/app_exception.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_roadmap.dart';
import '../../domain/entities/group_transaction.dart';

class GroupSupabaseDataSource {
  const GroupSupabaseDataSource(this.client);

  final SupabaseClient client;

  static const readTimeout = Duration(seconds: 15);
  static const mutationTimeout = Duration(seconds: 15);
  static const uploadTimeout = Duration(seconds: 30);

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final rows = await client
        .from('groups')
        .select()
        .eq('status', 'active')
        .order('updated_at', ascending: false);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchGroupsPage({
    required int limit,
    DateTime? beforeUpdatedAt,
    String? beforeId,
  }) async {
    final rows = await client
        .rpc(
          'list_my_group_summaries_v1',
          params: {
            'p_limit': limit,
            'p_before_updated_at': beforeUpdatedAt?.toUtc().toIso8601String(),
            'p_before_id': beforeId,
          },
        )
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    final rows = await client
        .from('group_members')
        .select(
          '*, profile:profiles!group_members_user_id_profiles_fkey(full_name,username,avatar_url,payment_qr_path)',
        )
        .eq('group_id', groupId)
        .order('joined_at')
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(String groupId) async {
    final rows = await client
        .from('group_transactions')
        .select(
          '*, creator:profiles!group_transactions_created_by_profiles_fkey(full_name)',
        )
        .eq('group_id', groupId)
        .neq('split_status', 'cancelled')
        .order('transaction_date', ascending: false)
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async {
    var request = client
        .from('group_transactions')
        .select(
          '*, creator:profiles!group_transactions_created_by_profiles_fkey(full_name)',
        )
        .eq('group_id', groupId)
        .neq('split_status', 'cancelled');
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      final escaped = normalizedQuery.replaceAll(',', '');
      request = request.or(
        'caption.ilike.%$escaped%,category_name_snapshot.ilike.%$escaped%,note.ilike.%$escaped%',
      );
    }
    if (status == 'posted') {
      request = request.eq('split_status', 'posted');
    } else if (status == 'pending') {
      request = request.neq('split_status', 'posted');
    }
    final rows = await request
        .order('transaction_date', ascending: false)
        .range(offset, offset + limit - 1)
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<Map<String, dynamic>> fetchGroup(String groupId) async {
    return await client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single()
        .timeout(readTimeout);
  }

  Future<Map<String, dynamic>> fetchGroupSummary(String groupId) async {
    return await client
        .rpc('get_group_summary_v1', params: {'p_group_id': groupId})
        .single()
        .timeout(readTimeout);
  }

  Future<Map<String, dynamic>> fetchTransaction(String transactionId) async {
    return await client
        .from('group_transactions')
        .select(
          '*, creator:profiles!group_transactions_created_by_profiles_fkey(full_name)',
        )
        .eq('id', transactionId)
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchPayers(String transactionId) async {
    final rows = await client
        .from('group_transaction_payers')
        .select(
          '*, profile:profiles!group_transaction_payers_user_id_profiles_fkey(full_name)',
        )
        .eq('group_transaction_id', transactionId)
        .order('created_at');
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchShares(String transactionId) async {
    final rows = await client
        .from('group_transaction_shares')
        .select(
          '*, profile:profiles!group_transaction_shares_user_id_profiles_fkey(full_name)',
        )
        .eq('group_transaction_id', transactionId)
        .order('created_at');
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchComments(String transactionId) async {
    final rows = await client
        .from('group_transaction_comments')
        .select(
          '*, profile:profiles!group_transaction_comments_user_id_profiles_fkey(full_name,avatar_url)',
        )
        .eq('group_transaction_id', transactionId)
        .order('created_at');
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchBalances(String groupId) async {
    final rows = await client
        .from('group_balance_summary')
        .select()
        .eq('group_id', groupId)
        .order('balance', ascending: false)
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchSettlements(String groupId) async {
    final rows = await client
        .from('group_settlement_suggestions')
        .select(
          '*, from_profile:profiles!group_settlements_from_user_profiles_fkey(full_name), to_profile:profiles!group_settlements_to_user_profiles_fkey(full_name)',
        )
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<Map<String, dynamic>> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) async {
    final result = await client.rpc(
      'get_group_monthly_stats',
      params: {
        'p_group_id': groupId,
        'p_month':
            '${month.year.toString().padLeft(4, '0')}-'
            '${month.month.toString().padLeft(2, '0')}-01',
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> fetchSettlementHistory(
    String groupId,
  ) async {
    final rows = await client.rpc(
      'list_group_settlement_history',
      params: {'p_group_id': groupId},
    );
    return _rows(rows);
  }

  Future<Map<String, dynamic>> fetchNotificationPreference(
    String groupId,
  ) async {
    final userId = _currentUserId();
    final row = await client
        .from('group_notification_preferences')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();
    return row ?? {'group_id': groupId};
  }

  Future<void> updateNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    return client.from('group_notification_preferences').upsert({
      'group_id': preference.groupId,
      'user_id': _currentUserId(),
      'mute_all': preference.muteAll,
      'transaction_notifications': preference.transactionNotifications,
      'debt_notifications': preference.debtNotifications,
      'invite_notifications': preference.inviteNotifications,
      'mention_notifications': preference.mentionNotifications,
      'community_comments': preference.communityComments,
      'community_reactions': preference.communityReactions,
      'quiet_hours_start': preference.quietHoursStart,
      'quiet_hours_end': preference.quietHoursEnd,
    }, onConflict: 'group_id,user_id');
  }

  Future<List<Map<String, dynamic>>> fetchReactionSummaries(
    String transactionId,
  ) async {
    final rows = await client.rpc(
      'list_group_transaction_reactions',
      params: {'p_transaction_id': transactionId},
    );
    return _rows(rows);
  }

  Future<Map<String, dynamic>> fetchBudget(String groupId) async {
    final row = await client
        .from('group_budgets')
        .select()
        .eq('group_id', groupId)
        .maybeSingle();
    return row ?? {'group_id': groupId};
  }

  Future<void> updateBudget(GroupBudget budget) {
    return client.from('group_budgets').upsert({
      'group_id': budget.groupId,
      'monthly_limit': budget.monthlyLimit,
      'warning_threshold_percent': budget.warningThresholdPercent,
    }, onConflict: 'group_id');
  }

  Future<Map<String, dynamic>> fetchPublicProfile(String groupId) async {
    final row = await client
        .from('group_public_profiles')
        .select()
        .eq('group_id', groupId)
        .maybeSingle();
    return row ?? {'group_id': groupId};
  }

  Future<void> updatePublicProfile(GroupPublicProfile profile) {
    return client.from('group_public_profiles').upsert({
      'group_id': profile.groupId,
      'is_enabled': profile.isEnabled,
      'show_stats': profile.showStats,
      'slug': profile.slug,
    }, onConflict: 'group_id');
  }

  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
  }) async {
    final result = await client.rpc(
      'create_expense_group',
      params: {'p_name': name, 'p_description': description, 'p_type': type},
    );
    return result as String;
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) {
    return client.rpc(
      'update_expense_group',
      params: {
        'p_group_id': groupId,
        'p_name': name,
        'p_description': description,
        'p_type': type,
      },
    );
  }

  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) {
    return client.rpc(
      'set_expense_group_archived',
      params: {'p_group_id': groupId, 'p_archived': archived},
    );
  }

  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) {
    return client.rpc(
      'update_group_currency',
      params: {'p_group_id': groupId, 'p_base_currency': baseCurrency},
    );
  }

  Future<String> createInviteLink(String groupId) async {
    final result = await client.rpc(
      'create_group_invite_link',
      params: {'p_group_id': groupId},
    );
    return result as String;
  }

  Future<Map<String, dynamic>> fetchInvitePreview(String token) async {
    final result = await client.rpc(
      'get_group_invite_preview',
      params: {'p_token': token},
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final result = await client.rpc(
      'accept_group_invite_link',
      params: {'p_token': token},
    );
    return result as Map<String, dynamic>;
  }

  Future<void> revokeInviteLink(String token) {
    return client.rpc('revoke_group_invite_link', params: {'p_token': token});
  }

  Future<List<Map<String, dynamic>>> fetchDirectInvites() async {
    final result = await client.rpc('get_my_group_invites');
    return _rows(result);
  }

  Future<Map<String, dynamic>> acceptDirectInvite(String inviteId) async {
    final result = await client.rpc(
      'accept_direct_group_invite',
      params: {'p_invite_id': inviteId},
    );
    return result as Map<String, dynamic>;
  }

  Future<void> declineDirectInvite(String inviteId) {
    return client.rpc(
      'decline_direct_group_invite',
      params: {'p_invite_id': inviteId},
    );
  }

  Future<void> declineInvite(String token) {
    return client.rpc('decline_group_invite', params: {'p_token': token});
  }

  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) {
    return client.rpc(
      'invite_group_member_by_username',
      params: {'p_group_id': groupId, 'p_username': username},
    );
  }

  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) {
    return client.rpc(
      'invite_group_member_by_user_id',
      params: {'p_group_id': groupId, 'p_user_id': userId},
    );
  }

  Future<String> createTransaction(GroupTransactionDraft draft) async {
    final result = await client.rpc(
      'create_group_transaction',
      params: {
        'p_group_id': draft.groupId,
        'p_total_amount': draft.totalAmount,
        'p_category_id': draft.categoryId,
        'p_category_name': draft.categoryName,
        'p_caption': draft.caption,
        'p_note': draft.note,
        'p_split_mode': draft.splitMode.value,
        'p_payment_mode': draft.paymentMode.value,
        'p_payer_amounts': draft.payerAmounts,
        'p_participant_ids': draft.participantIds,
        'p_share_amounts': draft.shareAmounts,
        'p_currency_code': draft.currencyCode,
        'p_exchange_rate_to_base': draft.exchangeRateToBase,
      },
    );
    return result as String;
  }

  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) {
    return client.rpc(
      'update_group_transaction',
      params: {
        'p_transaction_id': transactionId,
        'p_total_amount': draft.totalAmount,
        'p_category_id': draft.categoryId,
        'p_category_name': draft.categoryName,
        'p_caption': draft.caption,
        'p_note': draft.note,
        'p_split_mode': draft.splitMode.value,
        'p_payment_mode': draft.paymentMode.value,
        'p_payer_amounts': draft.payerAmounts,
        'p_participant_ids': draft.participantIds,
        'p_share_amounts': draft.shareAmounts,
        'p_currency_code': draft.currencyCode,
        'p_exchange_rate_to_base': draft.exchangeRateToBase,
      },
    );
  }

  Future<void> deleteTransaction(String transactionId) {
    return client.rpc(
      'delete_group_transaction',
      params: {'p_transaction_id': transactionId},
    );
  }

  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  }) {
    return client.rpc(
      'submit_group_member_amount',
      params: {
        'p_transaction_id': transactionId,
        'p_share_amount': shareAmount,
      },
    );
  }

  Future<void> markSettlementPaid(String settlementId) {
    return client.rpc(
      'mark_group_settlement_paid',
      params: {'p_settlement_id': settlementId},
    );
  }

  Future<void> confirmSettlementReceived(String settlementId) {
    return client.rpc(
      'confirm_group_settlement_received',
      params: {'p_settlement_id': settlementId},
    );
  }

  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  }) {
    return client.rpc(
      'dispute_group_settlement',
      params: {'p_settlement_id': settlementId, 'p_reason': reason},
    );
  }

  Future<void> resetDisputedSettlement(String settlementId) {
    return client.rpc(
      'reset_disputed_settlement',
      params: {'p_settlement_id': settlementId},
    );
  }

  Future<void> removeMember({required String groupId, required String userId}) {
    return client.rpc(
      'remove_group_member',
      params: {'p_group_id': groupId, 'p_user_id': userId},
    );
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) {
    return client.rpc(
      'update_group_member_role',
      params: {
        'p_group_id': groupId,
        'p_user_id': userId,
        'p_role': role.value,
      },
    );
  }

  Future<void> leaveGroup(String groupId) {
    return client
        .rpc('leave_expense_group', params: {'p_group_id': groupId})
        .then((result) {
          switch (result) {
            case 'left':
              return;
            case 'unresolved':
              throw const PostgrestException(message: 'GROUP_LEAVE_UNRESOLVED');
            case 'unresolved_transaction':
              throw const PostgrestException(
                message: 'GROUP_LEAVE_INCOMPLETE_TRANSACTION',
              );
            case 'disputed_settlement':
              throw const PostgrestException(
                message: 'GROUP_LEAVE_DISPUTED_SETTLEMENT',
              );
            case 'owner_transfer_required':
              throw const PostgrestException(
                message: 'GROUP_OWNER_TRANSFER_REQUIRED',
              );
            default:
              throw const PostgrestException(message: 'GROUP_LEAVE_FAILED');
          }
        });
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) {
    return client.rpc(
      'transfer_group_ownership',
      params: {'p_group_id': groupId, 'p_new_owner_user_id': newOwnerUserId},
    );
  }

  Future<void> addComment({
    required String transactionId,
    required String content,
  }) {
    return client.rpc(
      'add_group_transaction_comment',
      params: {'p_transaction_id': transactionId, 'p_content': content},
    );
  }

  Future<void> updateComment({
    required String commentId,
    required String content,
  }) {
    return client
        .from('group_transaction_comments')
        .update({'content': content})
        .eq('id', commentId);
  }

  Future<void> deleteComment(String commentId) {
    return client
        .from('group_transaction_comments')
        .delete()
        .eq('id', commentId);
  }

  Future<List<Map<String, dynamic>>> fetchReactions(
    String transactionId,
  ) async {
    final rows = await client.rpc(
      'list_group_transaction_reactions',
      params: {'p_transaction_id': transactionId},
    );
    return _rows(rows);
  }

  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) {
    return client.rpc(
      'toggle_group_transaction_reaction',
      params: {'p_transaction_id': transactionId, 'p_emoji': emoji},
    );
  }

  Future<List<Map<String, dynamic>>> fetchActivities(String groupId) async {
    final rows = await client.rpc(
      'list_group_activities',
      params: {'p_group_id': groupId},
    );
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchCommunityPosts({
    required String groupId,
    required int offset,
    required int limit,
  }) async {
    final rows = await client
        .from('group_community_posts')
        .select(
          '*, author:profiles!group_community_posts_author_user_id_fkey(full_name,avatar_url), media:group_community_media(*), reactions:group_community_post_reactions(emoji,user_id), comments:group_community_post_comments(*, profile:profiles!group_community_post_comments_user_id_fkey(full_name,avatar_url))',
        )
        .eq('group_id', groupId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchCommunityFeedPage({
    required String groupId,
    required int limit,
    DateTime? beforeCreatedAt,
    String? beforeType,
    String? beforeId,
  }) async {
    final rows = await client
        .rpc(
          'list_group_community_feed_v1',
          params: {
            'p_group_id': groupId,
            'p_limit': limit,
            'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(),
            'p_before_type': beforeType,
            'p_before_id': beforeId,
          },
        )
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchCommunityCommentsPage({
    required String postId,
    required int limit,
    DateTime? beforeCreatedAt,
    String? beforeId,
  }) async {
    final rows = await client
        .rpc(
          'list_group_community_comments_v1',
          params: {
            'p_post_id': postId,
            'p_limit': limit,
            'p_before_created_at': beforeCreatedAt?.toUtc().toIso8601String(),
            'p_before_id': beforeId,
          },
        )
        .timeout(readTimeout);
    return _rows(rows);
  }

  Future<String> createCommunityPost({
    required String groupId,
    required String type,
    String? content,
  }) async {
    final row = await client
        .from('group_community_posts')
        .insert({
          'group_id': groupId,
          'author_user_id': client.auth.currentUser!.id,
          'post_type': type,
          'content': content?.trim().isEmpty == true ? null : content?.trim(),
        })
        .select('id')
        .single()
        .timeout(mutationTimeout);
    return row['id'] as String;
  }

  Future<void> updateCommunityPost({
    required String postId,
    required String content,
  }) {
    return client
        .from('group_community_posts')
        .update({'content': content.trim()})
        .eq('id', postId)
        .timeout(mutationTimeout);
  }

  Future<void> deleteCommunityPost(String postId) {
    return client
        .from('group_community_posts')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', postId)
        .timeout(mutationTimeout);
  }

  Future<String> createCommunityMedia({
    required String groupId,
    required String postId,
    required String kind,
    String? caption,
  }) async {
    final row = await client
        .from('group_community_media')
        .insert({
          'group_id': groupId,
          'post_id': postId,
          'created_by': client.auth.currentUser!.id,
          'media_kind': kind,
          'caption': caption?.trim().isEmpty == true ? null : caption?.trim(),
          'upload_status': 'pending',
        })
        .select('id')
        .single()
        .timeout(mutationTimeout);
    return row['id'] as String;
  }

  Future<String> uploadCommunityMedia({
    required String groupId,
    required String mediaId,
    required String filePath,
  }) async {
    final path = 'group-community/$groupId/$mediaId.jpg';
    await client
        .from('group_community_media')
        .update({'upload_status': 'uploading'})
        .eq('id', mediaId)
        .timeout(mutationTimeout);
    await _uploadCompressed(path: path, filePath: filePath);
    await client
        .from('group_community_media')
        .update({'storage_path': path, 'upload_status': 'uploaded'})
        .eq('id', mediaId)
        .timeout(mutationTimeout);
    return path;
  }

  Future<void> markCommunityMediaUploadFailed(String mediaId) {
    return client
        .from('group_community_media')
        .update({'upload_status': 'failed'})
        .eq('id', mediaId)
        .timeout(mutationTimeout);
  }

  Future<void> addCommunityPostComment({
    required String postId,
    required String content,
  }) {
    return client
        .from('group_community_post_comments')
        .insert({
          'post_id': postId,
          'user_id': client.auth.currentUser!.id,
          'content': content.trim(),
        })
        .timeout(mutationTimeout);
  }

  Future<void> updateCommunityPostComment({
    required String commentId,
    required String content,
  }) {
    return client
        .from('group_community_post_comments')
        .update({'content': content.trim()})
        .eq('id', commentId)
        .timeout(mutationTimeout);
  }

  Future<void> deleteCommunityPostComment(String commentId) {
    return client
        .from('group_community_post_comments')
        .delete()
        .eq('id', commentId)
        .timeout(mutationTimeout);
  }

  Future<void> toggleCommunityPostReaction({
    required String postId,
    required String emoji,
  }) {
    return client
        .rpc(
          'toggle_group_community_post_reaction',
          params: {'p_post_id': postId, 'p_emoji': emoji},
        )
        .timeout(mutationTimeout);
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs(String groupId) async {
    final rows = await client.rpc(
      'list_group_audit_logs',
      params: {'p_group_id': groupId, 'p_limit': 100, 'p_offset': 0},
    );
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchPolls(String groupId) async {
    final rows = await client
        .from('group_polls')
        .select(
          '*, options:group_poll_options(id,label,vote_count), '
          'votes:group_poll_votes(user_id,option_id)',
        )
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return _rows(rows);
  }

  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) async {
    final result = await client
        .rpc(
          'create_group_poll',
          params: {
            'p_group_id': groupId,
            'p_title': title,
            'p_options': options,
          },
        )
        .timeout(mutationTimeout);
    return result as String;
  }

  Future<void> votePoll({required String pollId, required String optionId}) {
    return client
        .rpc(
          'vote_group_poll',
          params: {'p_poll_id': pollId, 'p_option_id': optionId},
        )
        .timeout(mutationTimeout);
  }

  Future<List<Map<String, dynamic>>> fetchSavingsChallenges(
    String groupId,
  ) async {
    final rows = await client
        .from('group_savings_challenges')
        .select('*, contributions:group_savings_contributions(amount)')
        .eq('group_id', groupId)
        .order('end_date');
    return _rows(rows);
  }

  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await client
        .rpc(
          'create_group_savings_challenge',
          params: {
            'p_group_id': groupId,
            'p_title': title,
            'p_target_amount': targetAmount,
            'p_start_date': startDate.toIso8601String().split('T').first,
            'p_end_date': endDate.toIso8601String().split('T').first,
          },
        )
        .timeout(mutationTimeout);
    return result as String;
  }

  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  }) {
    return client
        .rpc(
          'add_group_savings_contribution',
          params: {
            'p_challenge_id': challengeId,
            'p_amount': amount,
            'p_note': note,
          },
        )
        .timeout(mutationTimeout);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    String? category,
  }) async {
    final rows = await client.rpc(
      'list_group_notifications',
      params: {'p_category': category},
    );
    return _rows(rows);
  }

  Future<void> markNotificationRead(String notificationId) {
    return client.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<void> markAllNotificationsRead() {
    return client.rpc('mark_all_notifications_read');
  }

  Future<Map<String, dynamic>?> fetchPublicGroupProfile(String slug) async {
    final result = await client.rpc(
      'get_public_group_profile',
      params: {'p_slug': slug},
    );
    final values = _rows(result);
    return values.isEmpty ? null : values.first;
  }

  Future<List<Map<String, dynamic>>> fetchRecurringTransactions(
    String groupId,
  ) async {
    final rows = await client
        .from('group_recurring_transactions')
        .select()
        .eq('group_id', groupId)
        .order('next_run_at');
    return _rows(rows);
  }

  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool autoPost,
  }) async {
    final result = await client.rpc(
      'create_group_recurring_transaction',
      params: {
        'p_group_id': groupId,
        'p_title': title,
        'p_amount': amount,
        'p_frequency': frequency,
        'p_next_run_at': nextRunAt.toUtc().toIso8601String(),
        'p_notify_days_before': notifyDaysBefore,
        'p_auto_post': autoPost,
      },
    );
    return result as String;
  }

  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
    required bool autoPost,
  }) {
    return client.rpc(
      'update_group_recurring_transaction',
      params: {
        'p_id': id,
        'p_title': title,
        'p_amount': amount,
        'p_frequency': frequency,
        'p_next_run_at': nextRunAt.toUtc().toIso8601String(),
        'p_notify_days_before': notifyDaysBefore,
        'p_is_active': isActive,
        'p_auto_post': autoPost,
      },
    );
  }

  Future<void> deleteRecurringTransaction(String id) {
    return client.rpc(
      'delete_group_recurring_transaction',
      params: {'p_id': id},
    );
  }

  Future<String> uploadGroupAvatar({
    required String groupId,
    required String filePath,
  }) async {
    final path = 'groups/$groupId/avatar.jpg';
    await _uploadCompressed(path: path, filePath: filePath);
    await client.from('groups').update({'avatar_path': path}).eq('id', groupId);
    return path;
  }

  Future<String> uploadTransactionImage({
    required String groupId,
    required String transactionId,
    required String filePath,
  }) async {
    final path = 'group-transactions/$groupId/$transactionId.jpg';
    await client
        .from('group_transactions')
        .update({'image_upload_status': 'uploading'})
        .eq('id', transactionId);
    await _uploadCompressed(path: path, filePath: filePath);
    await client
        .from('group_transactions')
        .update({'image_path': path, 'image_upload_status': 'uploaded'})
        .eq('id', transactionId);
    return path;
  }

  Future<void> markImageUploadFailed(String transactionId) {
    return client
        .from('group_transactions')
        .update({'image_path': null, 'image_upload_status': 'failed'})
        .eq('id', transactionId);
  }

  Future<void> _uploadCompressed({
    required String path,
    required String filePath,
  }) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 1600,
      minHeight: 1600,
      quality: AppConstants.imageCompressQuality,
      format: CompressFormat.jpeg,
    ).timeout(uploadTimeout);
    final bytes = compressed ?? await File(filePath).readAsBytes();
    await client.storage
        .from(AppConstants.storageBucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        )
        .timeout(uploadTimeout);
  }

  List<Map<String, dynamic>> _rows(dynamic rows) =>
      (rows as List<dynamic>).cast<Map<String, dynamic>>();

  String _currentUserId() {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('AUTH_REQUIRED', code: 'AUTH_REQUIRED');
    }
    return userId;
  }
}
