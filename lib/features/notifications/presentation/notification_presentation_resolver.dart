import 'package:flutter/material.dart';

import '../../../l10n/gen_l10n/app_localizations.dart';
import '../domain/entities/app_notification.dart';

abstract final class NotificationPresentationResolver {
  const NotificationPresentationResolver._();

  static IconData iconFor(AppNotification notification) =>
      switch (notification.type) {
        'friend_request' ||
        'friend_request_accepted' => Icons.person_add_outlined,
        'group_invite' => Icons.group_add_outlined,
        'transaction_posted' ||
        'group_transaction_posted' ||
        'member_amount_required' ||
        'member_amount_input_required' ||
        'member_amount_mismatch' => Icons.receipt_long_outlined,
        'debt_settled' ||
        'settlement_marked_paid' ||
        'settlement_completed' ||
        'settlement_disputed' => Icons.handshake_outlined,
        'comment_added' ||
        'transaction_commented' ||
        'community_post_commented' ||
        'comment_mention' ||
        'mention' => Icons.chat_bubble_outline,
        'transaction_reacted' ||
        'community_post_reacted' => Icons.favorite_border_outlined,
        'challenge_contribution' => Icons.savings_outlined,
        'recurring_due' || 'recurring_transaction_due' => Icons.repeat_outlined,
        'member_joined' ||
        'member_joined_by_link' ||
        'member_invitation_accepted' ||
        'member_invitation_declined' ||
        'member_left' ||
        'member_removed' ||
        'member_role_updated' ||
        'owner_transferred' => Icons.groups_outlined,
        _ => switch (notification.category) {
          AppNotificationCategory.personal => Icons.person_outline,
          AppNotificationCategory.group => Icons.groups_outlined,
          AppNotificationCategory.community => Icons.forum_outlined,
          AppNotificationCategory.system => Icons.info_outline,
        },
      };

  static String title(
    AppLocalizations l10n,
    AppNotification notification,
    String languageCode,
  ) {
    final custom = _localizedMetadata(
      notification.metadata,
      'title',
      languageCode,
    );
    if (custom != null) return custom;

    return switch (notification.type) {
      'friend_request' => l10n.notificationFriendRequest,
      'friend_request_accepted' => l10n.notificationFriendAccepted,
      'transaction_posted' ||
      'group_transaction_posted' => l10n.notificationGroupTransaction,
      'member_amount_required' ||
      'member_amount_input_required' => l10n.notificationAmountRequired,
      'member_amount_mismatch' => l10n.notificationAmountMismatch,
      'group_invite' => l10n.notificationGroupInvite,
      'debt_settled' => l10n.notificationDebtSettled,
      'settlement_marked_paid' => l10n.notificationSettlementMarkedPaid,
      'settlement_completed' => l10n.notificationSettlementCompleted,
      'settlement_disputed' => l10n.notificationSettlementDisputed,
      'settlement_dispute_reset' => l10n.notificationSettlementDisputeReset,
      'comment_added' ||
      'transaction_commented' ||
      'community_post_commented' => l10n.notificationCommunityComment,
      'transaction_reacted' ||
      'community_post_reacted' => l10n.notificationCommunityReaction,
      'challenge_contribution' => l10n.notificationChallengeContribution,
      'comment_mention' || 'mention' => l10n.notificationCommunityMention,
      'member_joined' ||
      'member_joined_by_link' => l10n.notificationMemberJoined,
      'member_invitation_accepted' => l10n.notificationMemberInviteAccepted,
      'member_invitation_declined' => l10n.notificationMemberInviteDeclined,
      'member_left' => l10n.notificationMemberLeft,
      'member_removed' => l10n.notificationMemberRemoved,
      'member_role_updated' => l10n.notificationMemberRoleUpdated,
      'member_leave_blocked_warning' => l10n.notificationMemberLeaveBlocked,
      'owner_transferred' => l10n.notificationOwnerTransferred,
      'owner_transfer_required' => l10n.notificationOwnerTransferRequired,
      'recurring_due' ||
      'recurring_transaction_due' => l10n.notificationRecurringDue,
      _ => l10n.notificationGeneric,
    };
  }

  static String subtitle(
    AppLocalizations l10n,
    AppNotification notification,
    String languageCode,
  ) {
    final custom = _localizedMetadata(
      notification.metadata,
      'body',
      languageCode,
    );
    if (custom != null) return custom;
    final category = categoryLabel(l10n, notification.category);
    final groupName = notification.groupName?.trim();
    return groupName == null || groupName.isEmpty
        ? category
        : '$category · $groupName';
  }

  static String categoryLabel(
    AppLocalizations l10n,
    AppNotificationCategory category,
  ) => switch (category) {
    AppNotificationCategory.personal => l10n.notificationsCategoryPersonal,
    AppNotificationCategory.group => l10n.notificationsCategoryGroup,
    AppNotificationCategory.community => l10n.notificationsCategoryCommunity,
    AppNotificationCategory.system => l10n.notificationsCategorySystem,
  };

  static String? _localizedMetadata(
    Map<String, dynamic> metadata,
    String key,
    String languageCode,
  ) {
    final localized = _string(metadata['${key}_${languageCode.toLowerCase()}']);
    return localized ?? _string(metadata[key]);
  }

  static String? _string(Object? value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
