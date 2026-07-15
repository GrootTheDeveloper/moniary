import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/core/supabase/app_exception.dart';
import 'package:moniary/features/groups/data/datasources/group_mock_data_source.dart';
import 'package:moniary/features/groups/domain/entities/group_community_feed.dart';

void main() {
  setUp(() => GroupMockDataSource.resetForTesting());

  test('mock community feed has post, poll and challenge content', () async {
    final source = GroupMockDataSource(currentUserId: 'mock-user-id');

    final posts = await source.fetchCommunityPosts(
      groupId: 'mock-group-dalat',
      offset: 0,
      limit: 30,
    );
    final polls = await source.fetchPolls('mock-group-dalat');
    final challenges = await source.fetchSavingsChallenges('mock-group-dalat');

    expect(posts, isNotEmpty);
    expect(posts.first.content, contains('hóa đơn'));
    expect(polls, isNotEmpty);
    expect(challenges, isNotEmpty);
  });

  test('mock community post accepts text and media', () async {
    final source = GroupMockDataSource(currentUserId: 'mock-user-id');

    final postId = await source.createCommunityPost(
      groupId: 'mock-group-dalat',
      type: 'photo',
      content: 'Ảnh cả nhóm',
      media: const [
        GroupCommunityMediaDraft(
          localPath: 'asset://assets/demo_transactions/lunch.png',
        ),
      ],
    );
    final posts = await source.fetchCommunityPosts(
      groupId: 'mock-group-dalat',
      offset: 0,
      limit: 30,
    );

    expect(postId, isNotEmpty);
    expect(posts.first.media, hasLength(1));
    expect(posts.first.media.first.storagePath, contains('lunch.png'));
  });

  test('mock post reactions and comments update the feed item', () async {
    final source = GroupMockDataSource(currentUserId: 'mock-user-id');
    final initial = (await source.fetchCommunityPosts(
      groupId: 'mock-group-dalat',
      offset: 0,
      limit: 30,
    )).first;

    await source.toggleCommunityPostReaction(postId: initial.id, emoji: '❤️');
    await source.addCommunityPostComment(
      postId: initial.id,
      content: 'Mình đã lưu lại rồi!',
    );
    final updated = (await source.fetchCommunityPosts(
      groupId: 'mock-group-dalat',
      offset: 0,
      limit: 30,
    )).first;

    expect(updated.reactions.first.count, 1);
    expect(updated.comments.first.content, 'Mình đã lưu lại rồi!');
  });

  test('poll fetch preserves the current member selected option', () async {
    final source = GroupMockDataSource(currentUserId: 'mock-user-id');
    final poll = (await source.fetchPolls('mock-group-dalat')).first;
    final option = poll.options.first;

    await source.votePoll(pollId: poll.id, optionId: option.id);
    final refreshed = (await source.fetchPolls(
      'mock-group-dalat',
    )).firstWhere((item) => item.id == poll.id);

    expect(refreshed.selectedOptionId, option.id);
    expect(
      refreshed.options.firstWhere((item) => item.id == option.id).voteCount,
      option.voteCount + 1,
    );
  });

  test('post and comment authors or group admins can manage content', () async {
    final owner = GroupMockDataSource(currentUserId: 'owner');
    final member = GroupMockDataSource(currentUserId: 'member');
    final viewer = GroupMockDataSource(currentUserId: 'viewer');
    final groupId = await owner.createGroup(name: 'Community permissions');
    final invite = await owner.createInviteLink(groupId);
    final token = Uri.parse(invite).pathSegments.last;
    await member.acceptInvite(token);
    await viewer.acceptInvite(token);

    final postId = await member.createCommunityPost(
      groupId: groupId,
      type: 'text',
      content: 'Nội dung ban đầu',
    );
    await owner.updateCommunityPost(
      postId: postId,
      content: 'Chủ nhóm đã cập nhật',
    );
    expect(
      (await member.fetchCommunityPosts(
        groupId: groupId,
        offset: 0,
        limit: 30,
      )).single.content,
      'Chủ nhóm đã cập nhật',
    );
    expect(
      () => viewer.updateCommunityPost(
        postId: postId,
        content: 'Không được phép',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_COMMUNITY_POST_FORBIDDEN',
        ),
      ),
    );

    await member.addCommunityPostComment(
      postId: postId,
      content: 'Bình luận ban đầu',
    );
    final commentId = (await owner.fetchCommunityPosts(
      groupId: groupId,
      offset: 0,
      limit: 30,
    )).single.comments.single.id;
    await owner.updateCommunityPostComment(
      commentId: commentId,
      content: 'Đã kiểm duyệt nội dung',
    );
    expect(
      (await member.fetchCommunityPosts(
        groupId: groupId,
        offset: 0,
        limit: 30,
      )).single.comments.single.content,
      'Đã kiểm duyệt nội dung',
    );
    expect(
      () => viewer.deleteCommunityPostComment(commentId),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'GROUP_COMMENT_OWNER_REQUIRED',
        ),
      ),
    );

    await member.deleteCommunityPostComment(commentId);
    expect(
      (await owner.fetchCommunityPosts(
        groupId: groupId,
        offset: 0,
        limit: 30,
      )).single.comments,
      isEmpty,
    );
  });
}
