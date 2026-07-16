import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moniary/features/groups/application/group_controller.dart';
import 'package:moniary/features/groups/data/models/group_model_mapper.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/entities/group_community_feed.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/spending_group.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  test(
    'group list loads one summary page and uses the final row as cursor',
    () async {
      final repository = _MockGroupRepository();
      final firstUpdatedAt = DateTime(2026, 7, 16, 10);
      final first = _group('group-1', firstUpdatedAt);
      final second = _group(
        'group-2',
        firstUpdatedAt.subtract(const Duration(hours: 1)),
      );

      when(() => repository.fetchGroupsPage(limit: 20)).thenAnswer(
        (_) async => SpendingGroupPage(items: [first], hasMore: true),
      );
      when(
        () => repository.fetchGroupsPage(
          limit: 20,
          beforeUpdatedAt: firstUpdatedAt,
          beforeId: first.id,
        ),
      ).thenAnswer(
        (_) async => SpendingGroupPage(items: [second], hasMore: false),
      );
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(groupsControllerProvider.future);
      expect(initial.items, [first]);

      await container.read(groupsControllerProvider.notifier).loadMore();

      expect(container.read(groupsControllerProvider).requireValue.items, [
        first,
        second,
      ]);
      verify(() => repository.fetchGroupsPage(limit: 20)).called(1);
      verify(
        () => repository.fetchGroupsPage(
          limit: 20,
          beforeUpdatedAt: firstUpdatedAt,
          beforeId: first.id,
        ),
      ).called(1);
    },
  );

  test(
    'community reaction updates one item without reloading the feed',
    () async {
      final repository = _MockGroupRepository();
      final post = GroupModelMapper.communityPost({
        'id': 'post-1',
        'group_id': 'group-1',
        'author_user_id': 'user-1',
        'post_type': 'text',
        'content': 'Hello',
        'created_at': '2026-07-16T10:00:00Z',
        'author': {'full_name': 'User', 'avatar_url': null},
        'media': <Object?>[],
        'comments': <Object?>[],
        'comment_count': 42,
        'reactions': [
          {
            'emoji': '👍',
            'reaction_count': 7,
            'reacted_by_current_user': false,
          },
        ],
      }, currentUserId: 'current-user');
      final item = GroupCommunityFeedItem(
        id: 'post-post-1',
        sourceId: post.id,
        groupId: post.groupId,
        type: GroupCommunityFeedItemType.post,
        createdAt: post.createdAt,
        post: post,
      );
      when(
        () => repository.fetchCommunityFeedPage(groupId: 'group-1', limit: 20),
      ).thenAnswer(
        (_) async => GroupCommunityPage(items: [item], hasMore: false),
      );
      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(groupCommunityFeedProvider('group-1').future);
      container
          .read(groupCommunityFeedProvider('group-1').notifier)
          .togglePostReaction(post.id, '👍');

      final updated = container
          .read(groupCommunityFeedProvider('group-1'))
          .requireValue
          .items
          .single
          .post!;
      expect(updated.commentCount, 42);
      expect(updated.reactions.single.count, 8);
      expect(updated.reactions.single.reactedByCurrentUser, isTrue);
      verify(
        () => repository.fetchCommunityFeedPage(groupId: 'group-1', limit: 20),
      ).called(1);
    },
  );
}

SpendingGroup _group(String id, DateTime updatedAt) {
  return SpendingGroup(
    id: id,
    name: id,
    createdBy: 'user-1',
    status: GroupStatus.active,
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}
