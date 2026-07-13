import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/friend_profile.dart';

class FriendModelMapper {
  const FriendModelMapper._();

  static FriendProfile profile(Map<String, dynamic> row) {
    return FriendProfile(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String?,
      username: row['username'] as String?,
      avatarPath: row['avatar_url'] as String?,
      friendsSince: _date(row['friends_since']),
      sharedGroupCount: (row['shared_group_count'] as num?)?.toInt() ?? 0,
      currentUserBalance: (row['current_user_balance'] as num?)?.toInt() ?? 0,
    );
  }

  static FriendSearchResult searchResult(Map<String, dynamic> row) {
    return FriendSearchResult(
      profile: profile(row),
      relationStatus: FriendRelationStatus.fromValue(
        row['relation_status'] as String?,
      ),
    );
  }

  static FriendRequest request(
    Map<String, dynamic> row, {
    required bool isIncoming,
  }) {
    return FriendRequest(
      id: row['request_id'] as String,
      fromUserId: row['from_user_id'] as String,
      toUserId: row['to_user_id'] as String,
      otherUserId: row['other_user_id'] as String,
      fullName: row['full_name'] as String?,
      username: row['username'] as String?,
      avatarPath: row['avatar_url'] as String?,
      status: FriendRequestStatus.fromValue(row['status'] as String?),
      createdAt: _date(row['created_at']) ?? DateTime.now(),
      isIncoming: isIncoming,
    );
  }

  static FriendInviteLink inviteLink(Map<String, dynamic> row) {
    final token = row['token'] as String;
    return FriendInviteLink(
      token: token,
      link: AppConstants.friendInviteLink(token),
      expiresAt: _date(row['expires_at']) ?? DateTime.now(),
    );
  }

  static FriendInvitePreview invitePreview(Map<String, dynamic> row) {
    final inviterUserId = row['inviter_user_id'] as String?;
    final inviter = inviterUserId == null
        ? null
        : FriendProfile(
            userId: inviterUserId,
            fullName: row['full_name'] as String?,
            username: row['username'] as String?,
            avatarPath: row['avatar_url'] as String?,
          );
    return FriendInvitePreview(
      status: FriendInviteStatus.fromValue(row['invite_status'] as String?),
      relationStatus: FriendRelationStatus.fromValue(
        row['relation_status'] as String?,
      ),
      inviter: inviter,
      expiresAt: _date(row['expires_at']),
    );
  }

  static FriendInviteAcceptResult inviteAcceptResult(Map<String, dynamic> row) {
    return FriendInviteAcceptResult(
      status: FriendInviteAcceptStatus.fromValue(row['status'] as String?),
      inviterUserId: row['inviter_user_id'] as String?,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}
