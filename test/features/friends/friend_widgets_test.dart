import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moniary/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';
import 'package:moniary/features/friends/domain/repositories/friend_repository.dart';
import 'package:moniary/features/friends/presentation/screens/add_friend_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friends_screen.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/entities/group_settlement.dart';
import 'package:moniary/features/groups/domain/entities/group_transaction.dart';
import 'package:moniary/features/groups/domain/entities/spending_group.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';
import 'package:moniary/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  Widget app(
    Widget child, {
    required FakeFriendRepository friendRepository,
    FakeGroupRepository? groupRepository,
  }) {
    return ProviderScope(
      overrides: [
        friendRepositoryProvider.overrideWithValue(friendRepository),
        if (groupRepository != null)
          groupRepositoryProvider.overrideWithValue(groupRepository),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('AddFriendScreen tìm username và gửi lời mời', (tester) async {
    final repository = FakeFriendRepository(
      searchResults: [
        const FriendSearchResult(
          profile: FriendProfile(
            userId: 'user-an',
            fullName: 'An Nguyen',
            username: 'an_nguyen',
          ),
          relationStatus: FriendRelationStatus.none,
        ),
      ],
    );

    await tester.pumpWidget(
      app(const AddFriendScreen(), friendRepository: repository),
    );

    await tester.enterText(find.byType(TextField), 'an');
    await tester.tap(find.text('Tìm kiếm'));
    await tester.pumpAndSettle();

    expect(find.text('An Nguyen'), findsOneWidget);
    expect(find.text('@an_nguyen'), findsOneWidget);

    await tester.tap(find.text('Kết bạn'));
    await tester.pumpAndSettle();

    expect(repository.sentUsernames, ['an_nguyen']);
    expect(find.text('Đã gửi lời mời kết bạn.'), findsOneWidget);
  });

  testWidgets('FriendsScreen hiển thị empty state khi chưa có bạn', (
    tester,
  ) async {
    final repository = FakeFriendRepository();

    await tester.pumpWidget(
      app(const FriendsScreen(), friendRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có bạn bè nào.'), findsOneWidget);
    expect(find.text('Thêm bạn'), findsWidgets);
  });

  testWidgets('FriendsScreen chấp nhận incoming request', (tester) async {
    final repository = FakeFriendRepository(
      incoming: [
        FriendRequest(
          id: 'request-1',
          fromUserId: 'user-an',
          toUserId: 'mock-user-id',
          otherUserId: 'user-an',
          status: FriendRequestStatus.pending,
          createdAt: DateTime(2026),
          isIncoming: true,
          fullName: 'An Nguyen',
          username: 'an_nguyen',
        ),
      ],
    );

    await tester.pumpWidget(
      app(const FriendsScreen(), friendRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lời mời kết bạn'), findsOneWidget);
    await tester.tap(find.byTooltip('Chấp nhận'));
    await tester.pumpAndSettle();

    expect(repository.acceptedRequestIds, ['request-1']);
    expect(find.text('Đã chấp nhận lời mời kết bạn.'), findsOneWidget);
  });

  testWidgets('InviteMemberScreen hiển thị friends và mời bằng userId', (
    tester,
  ) async {
    final friendRepository = FakeFriendRepository(
      friends: const [
        FriendProfile(
          userId: 'user-an',
          fullName: 'An Nguyen',
          username: 'an_nguyen',
        ),
      ],
    );
    final groupRepository = FakeGroupRepository();

    await tester.pumpWidget(
      app(
        const InviteMemberScreen(groupId: 'group-1'),
        friendRepository: friendRepository,
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mời từ danh sách bạn bè'), findsOneWidget);
    expect(find.text('An Nguyen'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Gửi lời mời').last);
    await tester.pumpAndSettle();

    expect(groupRepository.invitedUserIds, ['user-an']);
    expect(find.text('Đã gửi lời mời.'), findsOneWidget);
  });
}

class FakeFriendRepository implements FriendRepository {
  FakeFriendRepository({
    List<FriendProfile>? friends,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
    List<FriendSearchResult>? searchResults,
  }) : friends = friends ?? [],
       incoming = incoming ?? [],
       outgoing = outgoing ?? [],
       searchResults = searchResults ?? [];

  final List<FriendProfile> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final List<FriendSearchResult> searchResults;
  final List<String> sentUsernames = [];
  final List<String> acceptedRequestIds = [];
  final List<String> declinedRequestIds = [];
  final List<String> cancelledRequestIds = [];
  final List<String> removedFriendIds = [];

  @override
  String get currentUserId => 'mock-user-id';

  @override
  Future<List<FriendProfile>> fetchFriends() async => friends;

  @override
  Future<List<FriendRequest>> fetchIncomingRequests() async => incoming;

  @override
  Future<List<FriendRequest>> fetchOutgoingRequests() async => outgoing;

  @override
  Future<List<FriendSearchResult>> searchUsers(String usernameQuery) async {
    return searchResults;
  }

  @override
  Future<void> sendRequest(String username) async {
    sentUsernames.add(username);
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    acceptedRequestIds.add(requestId);
    incoming.removeWhere((request) => request.id == requestId);
  }

  @override
  Future<void> declineRequest(String requestId) async {
    declinedRequestIds.add(requestId);
    incoming.removeWhere((request) => request.id == requestId);
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    cancelledRequestIds.add(requestId);
    outgoing.removeWhere((request) => request.id == requestId);
  }

  @override
  Future<void> removeFriend(String friendUserId) async {
    removedFriendIds.add(friendUserId);
    friends.removeWhere((friend) => friend.userId == friendUserId);
  }
}

class FakeGroupRepository implements GroupRepository {
  final List<String> invitedUserIds = [];

  @override
  String get currentUserId => 'mock-user-id';

  @override
  Future<void> inviteByUserId({
    required String groupId,
    required String userId,
  }) async {
    invitedUserIds.add(userId);
  }

  @override
  Future<void> inviteByUsername({
    required String groupId,
    required String username,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    String? type,
    String? avatarFilePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> createInviteLink(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<String> createTransaction(GroupTransactionDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTransaction({
    required String transactionId,
    required GroupTransactionDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<List<SpendingGroup>> fetchGroups() {
    throw UnimplementedError();
  }

  @override
  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<GroupSettlementOverview> fetchSettlementOverview(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupTransaction>> fetchTransactions(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<void> submitMemberAmount({
    required String transactionId,
    required int shareAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> markSettlementPaid(String settlementId) {
    throw UnimplementedError();
  }

  @override
  Future<void> confirmSettlementReceived(String settlementId) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveGroup(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<void> addComment({
    required String transactionId,
    required String content,
  }) {
    throw UnimplementedError();
  }
}
