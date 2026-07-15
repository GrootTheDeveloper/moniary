import 'package:flutter_test/flutter_test.dart';
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
}
