import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupSupabaseDataSource {
  const GroupSupabaseDataSource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final rows = await client
        .from('groups')
        .select()
        .eq('status', 'active')
        .order('updated_at', ascending: false);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchMembers(String groupId) async {
    final rows = await client
        .from('group_members')
        .select(
          '*, profile:profiles!group_members_user_id_profiles_fkey(full_name,username,avatar_url)',
        )
        .eq('group_id', groupId)
        .order('joined_at');
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
        .order('transaction_date', ascending: false);
    return _rows(rows);
  }

  Future<Map<String, dynamic>> fetchGroup(String groupId) async {
    return await client.from('groups').select().eq('id', groupId).single();
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
        .order('balance', ascending: false);
    return _rows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchSettlements(String groupId) async {
    final rows = await client
        .from('group_settlement_suggestions')
        .select(
          '*, from_profile:profiles!group_settlements_from_user_profiles_fkey(full_name), to_profile:profiles!group_settlements_to_user_profiles_fkey(full_name)',
        )
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return _rows(rows);
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

  Future<void> leaveGroup(String groupId) {
    return client
        .rpc('leave_expense_group', params: {'p_group_id': groupId})
        .then((result) {
          switch (result) {
            case 'left':
              return;
            case 'unresolved':
              throw const PostgrestException(message: 'GROUP_LEAVE_UNRESOLVED');
            case 'owner_transfer_required':
              throw const PostgrestException(
                message: 'GROUP_OWNER_TRANSFER_REQUIRED',
              );
            default:
              throw const PostgrestException(message: 'GROUP_LEAVE_FAILED');
          }
        });
  }

  Future<void> addComment({
    required String transactionId,
    required String content,
  }) {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('AUTH_REQUIRED');
    }
    return client.from('group_transaction_comments').insert({
      'group_transaction_id': transactionId,
      'user_id': userId,
      'content': content,
    });
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

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final rows = await client.rpc('list_group_notifications');
    return _rows(rows);
  }

  Future<void> markNotificationRead(String notificationId) {
    return client.rpc(
      'mark_group_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  Future<Map<String, dynamic>?> fetchBudget(String groupId) async {
    final rows = await client
        .from('group_budgets')
        .select()
        .eq('group_id', groupId);
    final values = _rows(rows);
    return values.isEmpty ? null : values.first;
  }

  Future<void> saveBudget(GroupBudget budget) {
    return client.from('group_budgets').upsert({
      'group_id': budget.groupId,
      'monthly_limit': budget.monthlyLimit,
      'warning_threshold_percent': budget.warningThresholdPercent,
    }, onConflict: 'group_id');
  }

  Future<Map<String, dynamic>?> fetchNotificationPreference({
    required String groupId,
    required String userId,
  }) async {
    final rows = await client
        .from('group_notification_preferences')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId);
    final values = _rows(rows);
    return values.isEmpty ? null : values.first;
  }

  Future<void> saveNotificationPreference({
    required String groupId,
    required String userId,
    required GroupNotificationPreference preference,
  }) {
    return client.from('group_notification_preferences').upsert({
      'group_id': groupId,
      'user_id': userId,
      'mute_all': preference.muteAll,
      'transaction_notifications': preference.transactionNotifications,
      'debt_notifications': preference.debtNotifications,
      'invite_notifications': preference.inviteNotifications,
      'mention_notifications': preference.mentionNotifications,
      'quiet_hours_start': preference.quietHoursStart,
      'quiet_hours_end': preference.quietHoursEnd,
    }, onConflict: 'group_id,user_id');
  }

  Future<Map<String, dynamic>?> fetchGroupPublicProfile(String groupId) async {
    final rows = await client
        .from('group_public_profiles')
        .select()
        .eq('group_id', groupId);
    final values = _rows(rows);
    return values.isEmpty ? null : values.first;
  }

  Future<void> saveGroupPublicProfile(GroupPublicProfile profile) {
    return client.from('group_public_profiles').upsert({
      'group_id': profile.groupId,
      'slug': profile.slug,
      'is_enabled': profile.isEnabled,
      'show_stats': profile.showStats,
    }, onConflict: 'group_id');
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
    );
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
        );
  }

  List<Map<String, dynamic>> _rows(dynamic rows) =>
      (rows as List<dynamic>).cast<Map<String, dynamic>>();
}
