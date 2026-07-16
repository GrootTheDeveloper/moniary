import 'group_community.dart';
import 'group_transaction.dart';

class GroupCommunityMediaDraft {
  const GroupCommunityMediaDraft({
    required this.localPath,
    this.kind = 'memory',
    this.caption,
  });

  final String localPath;
  final String kind;
  final String? caption;
}

class GroupCommunityMedia {
  const GroupCommunityMedia({
    required this.id,
    required this.groupId,
    required this.postId,
    required this.createdBy,
    required this.kind,
    required this.createdAt,
    this.storagePath,
    this.caption,
  });

  final String id;
  final String groupId;
  final String postId;
  final String createdBy;
  final String kind;
  final String? storagePath;
  final String? caption;
  final DateTime createdAt;

  bool get isReceipt => kind == 'receipt';
}

class GroupCommunityReactionSummary {
  const GroupCommunityReactionSummary({
    required this.emoji,
    required this.count,
    required this.reactedByCurrentUser,
  });

  final String emoji;
  final int count;
  final bool reactedByCurrentUser;
}

class GroupCommunityComment {
  const GroupCommunityComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.displayName,
    this.avatarPath,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? displayName;
  final String? avatarPath;
}

class GroupCommunityPost {
  const GroupCommunityPost({
    required this.id,
    required this.groupId,
    required this.authorUserId,
    required this.type,
    required this.createdAt,
    this.content,
    this.authorName,
    this.authorAvatarPath,
    this.media = const [],
    this.reactions = const [],
    this.comments = const [],
    int? commentCount,
    this.linkedTransactionId,
    this.linkedPollId,
    this.linkedChallengeId,
  }) : commentCount = commentCount ?? comments.length;

  final String id;
  final String groupId;
  final String authorUserId;
  final String type;
  final String? content;
  final String? authorName;
  final String? authorAvatarPath;
  final List<GroupCommunityMedia> media;
  final List<GroupCommunityReactionSummary> reactions;
  final List<GroupCommunityComment> comments;
  final int commentCount;
  final String? linkedTransactionId;
  final String? linkedPollId;
  final String? linkedChallengeId;
  final DateTime createdAt;

  bool get isPhotoPost => media.isNotEmpty || type == 'photo';

  GroupCommunityPost copyWith({
    String? content,
    List<GroupCommunityReactionSummary>? reactions,
    List<GroupCommunityComment>? comments,
    int? commentCount,
  }) {
    return GroupCommunityPost(
      id: id,
      groupId: groupId,
      authorUserId: authorUserId,
      type: type,
      content: content ?? this.content,
      authorName: authorName,
      authorAvatarPath: authorAvatarPath,
      media: media,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      commentCount: commentCount ?? this.commentCount,
      linkedTransactionId: linkedTransactionId,
      linkedPollId: linkedPollId,
      linkedChallengeId: linkedChallengeId,
      createdAt: createdAt,
    );
  }
}

enum GroupCommunityFeedItemType { post, poll, activity, challenge, transaction }

class GroupCommunityFeedItem {
  const GroupCommunityFeedItem({
    required this.id,
    required this.sourceId,
    required this.groupId,
    required this.type,
    required this.createdAt,
    this.post,
    this.poll,
    this.activity,
    this.challenge,
    this.transaction,
  });

  final String id;
  final String sourceId;
  final String groupId;
  final GroupCommunityFeedItemType type;
  final DateTime createdAt;
  final GroupCommunityPost? post;
  final GroupPoll? poll;
  final GroupActivity? activity;
  final GroupSavingsChallenge? challenge;
  final GroupTransaction? transaction;
}

class GroupCommunityFeed {
  const GroupCommunityFeed({
    required this.items,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.nextCursor,
  });

  final List<GroupCommunityFeedItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final GroupCommunityCursor? nextCursor;

  GroupCommunityFeed copyWith({
    List<GroupCommunityFeedItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    GroupCommunityCursor? nextCursor,
    bool clearCursor = false,
  }) {
    return GroupCommunityFeed(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    );
  }
}

class GroupCommunityCursor {
  const GroupCommunityCursor({
    required this.createdAt,
    required this.itemType,
    required this.itemId,
  });

  final DateTime createdAt;
  final String itemType;
  final String itemId;
}

class GroupCommunityPage {
  const GroupCommunityPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<GroupCommunityFeedItem> items;
  final bool hasMore;
  final GroupCommunityCursor? nextCursor;
}

class GroupCommunityCommentsPage {
  const GroupCommunityCommentsPage({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<GroupCommunityComment> items;
  final bool hasMore;
  final bool isLoadingMore;

  GroupCommunityCommentsPage copyWith({
    List<GroupCommunityComment>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GroupCommunityCommentsPage(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
