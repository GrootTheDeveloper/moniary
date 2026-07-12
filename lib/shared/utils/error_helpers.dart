import 'package:flutter/widgets.dart';
import '../../core/supabase/app_exception.dart';
import '../../l10n/l10n_extension.dart';

/// Returns a user-friendly Vietnamese message for any error.
/// Use this instead of `error.toString()` in SnackBars.
String userFriendlyMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is AppException) {
    switch (error.code) {
      case 'AUTH_REQUIRED':
        return l10n.errorNotLoggedIn;
      case 'LOCAL_AUTH_UNAVAILABLE':
        return l10n.errorLocalAuthUnavailable;
      case 'LOCAL_AUTH_FAILED':
        return l10n.errorLocalAuthFailed;
      case 'NOT_FOUND':
        return l10n.errorNotFound;
      case 'GROUP_NAME_REQUIRED':
        return l10n.groupNameRequired;
      case 'GROUP_USER_NOT_FOUND':
        return l10n.groupUserNotFound;
      case 'GROUP_MEMBER_ALREADY_INVITED':
        return l10n.groupMemberAlreadyInvited;
      case 'GROUP_INVITE_INVALID':
      case 'GROUP_INVITE_NOT_FOUND':
        return l10n.groupInviteInvalid;
      case 'GROUP_INVITE_EXPIRED':
        return l10n.groupInviteExpired;
      case 'GROUP_INVITE_USED':
        return l10n.groupInviteUsed;
      case 'GROUP_INVITE_REVOKED':
        return l10n.groupInviteRevoked;
      case 'GROUP_PAYER_REQUIRED':
        return l10n.groupSelectPayer;
      case 'GROUP_MULTIPLE_PAYERS_REQUIRED':
        return l10n.groupSelectAtLeastTwoPayers;
      case 'GROUP_PAYER_AMOUNT_INVALID':
        return l10n.groupPayerAmountPositive;
      case 'GROUP_PAID_TOTAL_MISMATCH':
        return l10n.groupPaidTotalMismatch;
      case 'GROUP_LEAVE_UNRESOLVED':
        return l10n.groupLeaveBlocked;
      case 'GROUP_OWNER_TRANSFER_REQUIRED':
        return l10n.groupOwnerTransferRequired;
      case 'GROUP_COMMENT_REQUIRED':
        return l10n.groupCommentRequired;
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
  return l10n.errorGeneric;
}
