import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';
import 'package:moniary/features/friends/domain/repositories/friend_repository.dart';
import 'package:moniary/features/friends/presentation/screens/add_friend_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friend_invite_accept_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friends_screen.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/group_invite.dart';
import 'package:moniary/features/groups/domain/entities/group_roadmap.dart';
import 'package:moniary/features/groups/domain/entities/group_settlement.dart';
import 'package:moniary/features/groups/domain/entities/group_transaction.dart';
import 'package:moniary/features/groups/domain/entities/spending_group.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';
import 'package:moniary/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_invitations_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_list_screen.dart';
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

  Widget routerApp({
    required FakeFriendRepository friendRepository,
    required String initialLocation,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: FriendInviteAcceptScreen.routePath,
          builder: (context, state) => FriendInviteAcceptScreen(
            token: state.pathParameters['token'] ?? '',
          ),
        ),
        GoRoute(
          path: FriendsScreen.routePath,
          builder: (context, state) => const FriendsScreen(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [friendRepositoryProvider.overrideWithValue(friendRepository)],
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
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

    expect(repository.sentUserIds, ['user-an']);
    expect(find.text('Đã gửi lời mời kết bạn.'), findsOneWidget);
  });

  testWidgets('AddFriendScreen chấp nhận lời mời đến từ kết quả tìm kiếm', (
    tester,
  ) async {
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
      searchResults: [
        const FriendSearchResult(
          profile: FriendProfile(
            userId: 'user-an',
            fullName: 'An Nguyen',
            username: 'an_nguyen',
          ),
          relationStatus: FriendRelationStatus.incomingPending,
        ),
      ],
    );

    await tester.pumpWidget(
      app(const AddFriendScreen(), friendRepository: repository),
    );

    await tester.enterText(find.byType(TextField), 'an');
    await tester.tap(find.text('Tìm kiếm'));
    await tester.pumpAndSettle();

    expect(find.text('Người này đã gửi lời mời cho bạn'), findsOneWidget);

    await tester.tap(find.byTooltip('Chấp nhận'));
    await tester.pumpAndSettle();

    expect(repository.acceptedRequestIds, ['request-1']);
    expect(find.text('Đã chấp nhận lời mời kết bạn.'), findsOneWidget);
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
    expect(find.byTooltip('Chia sẻ link kết bạn'), findsOneWidget);
  });

  testWidgets('AddFriendScreen hiển thị card chia sẻ link kết bạn', (
    tester,
  ) async {
    final repository = FakeFriendRepository();

    await tester.pumpWidget(
      app(const AddFriendScreen(), friendRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chia sẻ link kết bạn'), findsOneWidget);
    expect(
      find.text('Gửi link cho người khác để họ kết bạn với bạn nhanh hơn.'),
      findsOneWidget,
    );
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

  testWidgets('GroupInvitationsScreen cho phép từ chối lời mời trực tiếp', (
    tester,
  ) async {
    final groupRepository = FakeGroupRepository(
      directInvites: [
        GroupDirectInvite(
          id: 'invite-1',
          groupId: 'group-1',
          groupName: 'Chuyến đi Đà Lạt',
          inviterName: 'An Nguyen',
          status: GroupDirectInviteStatus.pending,
          createdAt: DateTime(2026, 7, 1),
          expiresAt: DateTime(2026, 7, 8),
        ),
      ],
    );

    await tester.pumpWidget(
      app(
        const GroupInvitationsScreen(),
        friendRepository: FakeFriendRepository(),
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuyến đi Đà Lạt'), findsOneWidget);
    expect(find.text('Đang chờ'), findsOneWidget);

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    expect(groupRepository.declinedInviteIds, ['invite-1']);
    expect(find.text('Bạn chưa có lời mời nhóm nào.'), findsOneWidget);
  });

  testWidgets('GroupListScreen hiển thị badge lời mời đang chờ', (
    tester,
  ) async {
    final groupRepository = FakeGroupRepository(
      directInvites: [
        GroupDirectInvite(
          id: 'invite-1',
          groupId: 'group-1',
          groupName: 'Chuyến đi Đà Lạt',
          inviterName: 'An Nguyen',
          status: GroupDirectInviteStatus.pending,
          createdAt: DateTime(2026, 7, 1),
          expiresAt: DateTime(2026, 7, 8),
        ),
      ],
    );

    await tester.pumpWidget(
      app(
        const GroupListScreen(),
        friendRepository: FakeFriendRepository(),
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Lời mời nhóm'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('InviteMemberScreen disable bạn đã là thành viên nhóm', (
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
    final groupRepository = FakeGroupRepository(
      members: [
        SpendingGroupMember(
          id: 'member-an',
          groupId: 'group-1',
          userId: 'user-an',
          role: GroupRole.member,
          status: GroupMemberStatus.active,
          joinedAt: DateTime(2026),
          displayName: 'An Nguyen',
          username: 'an_nguyen',
        ),
      ],
    );

    await tester.pumpWidget(
      app(
        const InviteMemberScreen(groupId: 'group-1'),
        friendRepository: friendRepository,
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('An Nguyen'), findsOneWidget);
    expect(find.text('Đang tham gia'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Gửi lời mời'), findsOneWidget);
    expect(groupRepository.invitedUserIds, isEmpty);
  });

  testWidgets('FriendInviteAcceptScreen preview và accept invite', (
    tester,
  ) async {
    final repository = FakeFriendRepository(
      invitePreview: const FriendInvitePreview(
        status: FriendInviteStatus.active,
        relationStatus: FriendRelationStatus.none,
        inviter: FriendProfile(
          userId: 'user-an',
          fullName: 'An Nguyen',
          username: 'an_nguyen',
        ),
      ),
    );

    await tester.pumpWidget(
      routerApp(
        friendRepository: repository,
        initialLocation: '/friends/invite/token-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('An Nguyen'), findsOneWidget);
    expect(
      find.text('An Nguyen muốn kết bạn với bạn trên Moniary.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Kết bạn'));
    await tester.pumpAndSettle();

    expect(repository.acceptedInviteTokens, ['token-1']);
    expect(find.text('Bạn bè'), findsWidgets);
    expect(find.text('An Nguyen'), findsOneWidget);
  });
}

class FakeFriendRepository implements FriendRepository {
  FakeFriendRepository({
    List<FriendProfile>? friends,
    List<FriendRequest>? incoming,
    List<FriendRequest>? outgoing,
    List<FriendSearchResult>? searchResults,
    FriendInvitePreview? invitePreview,
  }) : friends = friends ?? [],
       incoming = incoming ?? [],
       outgoing = outgoing ?? [],
       searchResults = searchResults ?? [],
       invitePreview =
           invitePreview ??
           const FriendInvitePreview(
             status: FriendInviteStatus.invalid,
             relationStatus: FriendRelationStatus.none,
           );

  final List<FriendProfile> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final List<FriendSearchResult> searchResults;
  FriendInvitePreview invitePreview;
  final List<String> sentUsernames = [];
  final List<String> sentUserIds = [];
  final List<String> acceptedRequestIds = [];
  final List<String> declinedRequestIds = [];
  final List<String> cancelledRequestIds = [];
  final List<String> removedFriendIds = [];
  final List<String> acceptedInviteTokens = [];
  final List<String> revokedInviteTokens = [];

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
  Future<FriendInviteLink> createInviteLink() async {
    return FriendInviteLink(
      token: 'token-1',
      link: 'https://go.vuivethoima.id.vn/friends/invite/token-1',
      expiresAt: DateTime(2026),
    );
  }

  @override
  Future<FriendInvitePreview> fetchInvitePreview(String token) async {
    return invitePreview;
  }

  @override
  Future<FriendInviteAcceptResult> acceptInvite(String token) async {
    acceptedInviteTokens.add(token);
    friends.add(invitePreview.inviter!);
    invitePreview = FriendInvitePreview(
      status: FriendInviteStatus.alreadyFriends,
      relationStatus: FriendRelationStatus.friends,
      inviter: invitePreview.inviter,
      expiresAt: invitePreview.expiresAt,
    );
    return const FriendInviteAcceptResult(
      status: FriendInviteAcceptStatus.accepted,
      inviterUserId: 'user-an',
    );
  }

  @override
  Future<void> revokeInviteLink(String token) async {
    revokedInviteTokens.add(token);
  }

  @override
  Future<void> sendRequest(String username) async {
    sentUsernames.add(username);
  }

  @override
  Future<void> sendRequestToUser(String userId) async {
    sentUserIds.add(userId);
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
  FakeGroupRepository({
    List<SpendingGroupMember>? members,
    List<GroupDirectInvite>? directInvites,
  }) : members = members ?? const [],
       directInvites = [...?directInvites];

  final List<SpendingGroupMember> members;
  final List<String> invitedUserIds = [];
  final List<GroupDirectInvite> directInvites;
  final List<String> declinedInviteIds = [];

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
  Future<GroupInvitePreview> fetchInvitePreview(String token) {
    throw UnimplementedError();
  }

  @override
  Future<GroupInviteAcceptResult> acceptInvite(String token) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeInviteLink(String token) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupDirectInvite>> fetchDirectInvites() async => directInvites;

  @override
  Future<GroupInviteAcceptResult> acceptDirectInvite(String inviteId) {
    final invite = directInvites.firstWhere((item) => item.id == inviteId);
    directInvites.removeWhere((item) => item.id == inviteId);
    return Future.value(
      GroupInviteAcceptResult(
        status: GroupInviteStatus.accepted,
        groupId: invite.groupId,
      ),
    );
  }

  @override
  Future<void> declineDirectInvite(String inviteId) {
    declinedInviteIds.add(inviteId);
    directInvites.removeWhere((item) => item.id == inviteId);
    return Future.value();
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
  Future<List<SpendingGroup>> fetchGroups() async => const [];

  @override
  Future<SpendingGroupDetail> fetchGroupDetail(String groupId) async {
    final now = DateTime(2026);
    return SpendingGroupDetail(
      group: SpendingGroup(
        id: groupId,
        name: 'Group',
        createdBy: currentUserId,
        status: GroupStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      members: [
        SpendingGroupMember(
          id: 'member-current',
          groupId: groupId,
          userId: currentUserId,
          role: GroupRole.owner,
          status: GroupMemberStatus.active,
          joinedAt: now,
          displayName: 'Mock User',
          username: 'mock-user',
        ),
        ...members,
      ],
      currentUserRole: GroupRole.owner,
    );
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

  @override
  Future<GroupBudget?> fetchGroupBudget(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertGroupBudget({
    required String groupId,
    required int monthlyLimit,
    required int warningThresholdPercent,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertNotificationPreference(
    GroupNotificationPreference preference,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<GroupPublicProfile> fetchPublicProfile(String groupId) {
    throw UnimplementedError();
  }

  @override
  Future<void> upsertPublicProfile(GroupPublicProfile profile) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateRecurringTransaction({
    required String id,
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
  }) {
    throw UnimplementedError();
  }
}
