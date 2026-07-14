import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_exception.dart';
import '../../l10n/l10n_extension.dart';

/// Returns a user-friendly Vietnamese message for any error.
/// Use this instead of `error.toString()` in SnackBars.
String userFriendlyMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AppException) {
    final authMessage = _authErrorMessage(context, error.code);
    if (authMessage != null) return authMessage;

    switch (error.code) {
      case 'AUTH_REQUIRED':
        return l10n.errorNotLoggedIn;
      case 'LOCAL_AUTH_UNAVAILABLE':
        return l10n.errorLocalAuthUnavailable;
      case 'LOCAL_AUTH_FAILED':
        return l10n.errorLocalAuthFailed;
      case 'NOT_FOUND':
        return l10n.errorNotFound;
      case 'AUTH_NETWORK_ERROR':
        return l10n.errorConnection;
      case 'AUTH_SIGN_IN_FAILED':
      case 'AUTH_SIGN_UP_FAILED':
      case 'AUTH_SIGN_OUT_FAILED':
      case 'AUTH_LINK_EMAIL_FAILED':
      case 'AUTH_LINK_GOOGLE_FAILED':
      case 'AUTH_LINK_FACEBOOK_FAILED':
      case 'AUTH_PASSWORD_UPDATE_FAILED':
        return l10n.errorGeneric;
      case 'invalid_credentials':
        return l10n.authErrorInvalidCredentials;
      case 'email_not_confirmed':
        return l10n.authErrorEmailNotConfirmed;
      case 'user_already_exists':
      case 'email_exists':
        return l10n.authErrorEmailAlreadyRegistered;
      case 'weak_password':
        return l10n.authErrorWeakPassword;
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return l10n.authErrorRateLimited;
      case 'user_banned':
        return l10n.authErrorUserBanned;
      case 'AUTH_LINK_EMAIL_NOT_CONFIRMED':
      case 'AUTH_LINK_EMAIL_NOT_PENDING':
        return l10n.emailLinkNotConfirmed;
      case 'GROUP_NAME_REQUIRED':
        return l10n.groupNameRequired;
      case 'GROUP_USER_NOT_FOUND':
        return l10n.groupUserNotFound;
      case 'GROUP_MEMBER_ALREADY_INVITED':
        return l10n.groupMemberAlreadyInvited;
      case 'GROUP_INVITE_INVALID':
      case 'GROUP_INVITE_NOT_FOUND':
      case 'GROUP_INVITE_FORBIDDEN':
        return l10n.groupInviteInvalid;
      case 'GROUP_INVITE_EXPIRED':
        return l10n.groupInviteExpired;
      case 'GROUP_INVITE_USED':
        return l10n.groupInviteUsed;
      case 'GROUP_INVITE_NOT_PENDING':
        return l10n.groupInviteAlreadyAccepted;
      case 'GROUP_INVITE_REVOKED':
        return l10n.groupInviteRevoked;
      case 'GROUP_INVITE_ARCHIVED':
        return l10n.groupInviteGroupArchived;
      case 'GROUP_DIRECT_INVITE_INVALID':
        return l10n.groupInvitationInvalid;
      case 'GROUP_DIRECT_INVITE_EXPIRED':
        return l10n.groupInvitationExpired;
      case 'GROUP_DIRECT_INVITE_DECLINED':
        return l10n.groupInvitationDeclined;
      case 'GROUP_DIRECT_INVITE_REVOKED':
        return l10n.groupInvitationRevoked;
      case 'GROUP_INVITE_DECLINED':
        return l10n.groupInvitationDeclined;
      case 'GROUP_PAYER_REQUIRED':
        return l10n.groupSelectPayer;
      case 'GROUP_MULTIPLE_PAYERS_REQUIRED':
        return l10n.groupSelectAtLeastTwoPayers;
      case 'GROUP_PAYER_AMOUNT_INVALID':
        return l10n.groupPayerAmountPositive;
      case 'GROUP_PAID_TOTAL_MISMATCH':
        return l10n.groupPaidTotalMismatch;
      case 'GROUP_PARTICIPANT_NOT_ACTIVE':
      case 'GROUP_NO_PARTICIPANTS':
        return l10n.groupNoMembers;
      case 'GROUP_SHARE_TOTAL_MISMATCH':
        return l10n.groupTransactionAmountMismatch;
      case 'GROUP_DISPUTE_REASON_REQUIRED':
        return l10n.groupSettlementDisputeReasonRequired;
      case 'GROUP_MEMBER_REMOVE_UNRESOLVED':
        return l10n.groupMemberRemoveUnresolved;
      case 'GROUP_MEMBER_REMOVE_FORBIDDEN':
      case 'GROUP_OWNER_TARGET_INVALID':
        return l10n.groupMemberActionForbidden;
      case 'GROUP_LEAVE_UNRESOLVED':
        return l10n.groupLeaveBlocked;
      case 'GROUP_LEAVE_INCOMPLETE_TRANSACTION':
        return l10n.groupLeaveIncompleteTransaction;
      case 'GROUP_LEAVE_DISPUTED_SETTLEMENT':
        return l10n.groupLeaveDisputedSettlement;
      case 'GROUP_OWNER_TRANSFER_REQUIRED':
        return l10n.groupOwnerTransferRequired;
      case 'GROUP_OWNER_REQUIRED':
        return l10n.groupOwnerRequired;
      case 'GROUP_OWNER_TRANSFER_TARGET_REQUIRED':
        return l10n.groupOwnerTransferTargetRequired;
      case 'GROUP_COMMENT_REQUIRED':
        return l10n.groupCommentRequired;
      case 'GROUP_COMMENT_OWNER_REQUIRED':
        return l10n.groupActionFailed;
      case 'GROUP_CREATOR_ONLY':
        return l10n.groupTransactionCreatorOnly;
      case 'FRIEND_USER_NOT_FOUND':
        return l10n.friendUserNotFound;
      case 'FRIEND_CANNOT_ADD_SELF':
        return l10n.friendCannotAddSelf;
      case 'FRIEND_ALREADY_EXISTS':
        return l10n.friendAlreadyExists;
      case 'FRIEND_REQUEST_ALREADY_PENDING':
        return l10n.friendRequestAlreadyPending;
      case 'FRIEND_REQUEST_NOT_FOUND':
        return l10n.friendRequestNotFound;
      case 'FRIEND_RATE_LIMITED':
        return l10n.friendRateLimited;
      case 'FRIEND_NOT_FOUND':
        return l10n.friendNotFound;
      case 'FRIEND_INVITE_INVALID':
        return l10n.friendInviteInvalid;
      case 'FRIEND_INVITE_EXPIRED':
        return l10n.friendInviteExpired;
      case 'FRIEND_INVITE_USED':
        return l10n.friendInviteUsed;
      case 'FRIEND_INVITE_REVOKED':
        return l10n.friendInviteRevoked;
      case 'FRIEND_INVITE_SELF':
        return l10n.friendInviteSelf;
      case 'FRIEND_INVITE_NOT_FOUND':
        return l10n.friendInviteInvalid;
    }

    switch (error.message) {
      case 'errorConnection':
        return l10n.errorConnection;
      case 'errorGeneric':
        return l10n.errorGeneric;
    }

    return l10n.errorGeneric;
  }
  if (error is AuthException) {
    return _authErrorMessage(context, error.code) ?? l10n.errorGeneric;
  }
  if (_looksLikeNetworkError(error)) {
    return l10n.errorConnection;
  }
  return l10n.errorGeneric;
}

String? _authErrorMessage(BuildContext context, String? code) {
  final l10n = context.l10n;
  return switch (code) {
    'invalid_credentials' => l10n.authErrorInvalidCredentials,
    'email_not_confirmed' => l10n.authErrorEmailNotConfirmed,
    'provider_disabled' ||
    'oauth_provider_not_supported' ||
    'email_provider_disabled' => l10n.authErrorProviderDisabled,
    'bad_oauth_state' ||
    'bad_oauth_callback' ||
    'bad_code_verifier' ||
    'flow_state_not_found' ||
    'flow_state_expired' => l10n.authErrorOAuthCallback,
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' => l10n.authErrorRateLimited,
    'email_exists' ||
    'user_already_exists' => l10n.authErrorEmailAlreadyRegistered,
    'weak_password' => l10n.authErrorWeakPassword,
    'signup_disabled' => l10n.authErrorSignupDisabled,
    'AUTH_OAUTH_LAUNCH_FAILED' => l10n.authErrorBrowserLaunch,
    _ => null,
  };
}

bool _looksLikeNetworkError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('network is unreachable') ||
      message.contains('connection timed out');
}
