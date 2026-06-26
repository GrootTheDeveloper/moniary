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

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }
}
