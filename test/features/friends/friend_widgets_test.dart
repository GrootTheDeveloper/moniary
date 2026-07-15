import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/friends/data/repositories/friend_repository_impl.dart';
import 'package:moniary/features/friends/domain/entities/friend_profile.dart';
import 'package:moniary/features/friends/domain/repositories/friend_repository.dart';
import 'package:moniary/features/friends/presentation/screens/add_friend_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friend_invite_accept_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friends_screen.dart';
import 'package:moniary/features/groups/data/repositories/group_repository_impl.dart';
import 'package:moniary/features/groups/domain/entities/group_community.dart';
import 'package:moniary/features/groups/domain/entities/group_enums.dart';
import 'package:moniary/features/groups/domain/entities/group_invite.dart';
import 'package:moniary/features/groups/domain/entities/group_roadmap.dart';
import 'package:moniary/features/groups/domain/entities/group_settlement.dart';
import 'package:moniary/features/groups/domain/entities/group_transaction.dart';
import 'package:moniary/features/groups/domain/entities/spending_group.dart';
import 'package:moniary/features/groups/domain/repositories/group_repository.dart';
import 'package:moniary/features/groups/presentation/screens/group_activity_center_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:moniary/features/groups/presentation/screens/invite_member_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_invitations_screen.dart';
import 'package:moniary/features/groups/presentation/screens/group_list_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(
    Widget child, {
    required FakeFriendRepository friendRepository,
    FakeGroupRepository? groupRepository,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        friendRepositoryProvider.overrideWithValue(friendRepository),
      ],
      child: MaterialApp.router(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Widget groupRouterApp({
    required FakeGroupRepository groupRepository,
    String initialLocation = GroupListScreen.routePath,
    String detailGroupId = 'group-1',
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: GroupListScreen.routePath,
          builder: (context, state) => const GroupListScreen(),
        ),
        GoRoute(
          path: GroupActivityCenterScreen.routePath,
          builder: (context, state) =>
              GroupActivityCenterScreen(groupId: state.extra as String?),
        ),
        GoRoute(
          path: GroupDetailScreen.routePath,
          builder: (context, state) =>
              GroupDetailScreen(groupId: detailGroupId),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        friendRepositoryProvider.overrideWithValue(FakeFriendRepository()),
        groupRepositoryProvider.overrideWithValue(groupRepository),
      ],
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

    await tester.tap(find.byTooltip('Chấp nhận').last);
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
    await tester.tap(find.byTooltip('Lời mời kết bạn'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lời mời kết bạn nào.'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

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
    expect(find.byTooltip('Lời mời kết bạn'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byTooltip('Lời mời kết bạn'));
    await tester.pumpAndSettle();

    expect(find.text('An Nguyen'), findsWidgets);

    await tester.tap(find.byTooltip('Chấp nhận').last);
    await tester.pumpAndSettle();

    expect(repository.acceptedRequestIds, ['request-1']);
    expect(find.text('Đã chấp nhận lời mời kết bạn.'), findsOneWidget);
  });

  testWidgets('FriendsScreen giữ layout trên màn hình hẹp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );

    final repository = FakeFriendRepository(
      friends: const [
        FriendProfile(
          userId: 'friend-long',
          fullName: 'Nguyễn Trần Minh Anh Hoàng Long',
          username: 'nguyen_tran_minh_anh_hoang_long',
          sharedGroupCount: 12,
          currentUserBalance: 123456789,
        ),
      ],
      incoming: [
        FriendRequest(
          id: 'incoming-long',
          fromUserId: 'friend-incoming',
          toUserId: 'mock-user-id',
          otherUserId: 'friend-incoming',
          status: FriendRequestStatus.pending,
          createdAt: DateTime(2026),
          isIncoming: true,
          fullName: 'Một Người Bạn Có Tên Rất Dài',
          username: 'mot_nguoi_ban_co_ten_rat_dai',
        ),
      ],
      outgoing: [
        FriendRequest(
          id: 'outgoing-long',
          fromUserId: 'mock-user-id',
          toUserId: 'friend-outgoing',
          otherUserId: 'friend-outgoing',
          status: FriendRequestStatus.pending,
          createdAt: DateTime(2026),
          isIncoming: false,
          fullName: 'Bạn Đang Chờ Xác Nhận Rất Dài',
          username: 'ban_dang_cho_xac_nhan_rat_dai',
        ),
      ],
    );

    await tester.pumpWidget(
      app(const FriendsScreen(), friendRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Lời mời kết bạn'), findsOneWidget);
    expect(find.text('Đã gửi lời mời'), findsOneWidget);
    expect(find.byTooltip('Chấp nhận'), findsOneWidget);
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

  testWidgets('GroupListScreen hiển thị nút thông báo nhóm', (tester) async {
    final groupRepository = FakeGroupRepository(
      notifications: [
        GroupNotification(
          id: 'notification-1',
          groupId: 'group-1',
          groupName: 'Chuyến đi Đà Lạt',
          type: 'transaction_posted',
          isRead: false,
          createdAt: DateTime(2026, 7, 1),
          groupTransactionId: 'transaction-1',
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

    expect(find.byTooltip('Thông báo'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('GroupListScreen bấm nút thông báo mở notification inbox', (
    tester,
  ) async {
    final groupRepository = FakeGroupRepository(
      notifications: [
        GroupNotification(
          id: 'notification-1',
          groupId: 'group-1',
          groupName: 'Chuyến đi Đà Lạt',
          type: 'transaction_posted',
          isRead: false,
          createdAt: DateTime(2026, 7, 1),
          groupTransactionId: 'transaction-1',
        ),
        GroupNotification(
          id: 'notification-2',
          groupId: 'group-2',
          groupName: 'Nhà chung',
          type: 'debt_settled',
          isRead: false,
          createdAt: DateTime(2026, 7, 2),
        ),
      ],
    );

    await tester.pumpWidget(groupRouterApp(groupRepository: groupRepository));
    await tester.pumpAndSettle();

    final notificationButton = find.byTooltip('Thông báo');
    expect(notificationButton, findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(notificationButton);
    await tester.pumpAndSettle();

    expect(find.text('Có giao dịch mới'), findsOneWidget);
    expect(find.text('Một khoản nợ đã được tất toán'), findsOneWidget);
  });

  testWidgets('GroupActivityCenterScreen mở thông báo không cần nhóm', (
    tester,
  ) async {
    final groupRepository = FakeGroupRepository(
      notifications: [
        GroupNotification(
          id: 'notification-1',
          groupId: 'group-1',
          groupName: 'Chuyến đi Đà Lạt',
          type: 'transaction_posted',
          isRead: false,
          createdAt: DateTime(2026, 7, 1),
          groupTransactionId: 'transaction-1',
        ),
      ],
    );

    await tester.pumpWidget(
      app(
        const GroupActivityCenterScreen(),
        friendRepository: FakeFriendRepository(),
        groupRepository: groupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsWidgets);
    expect(find.text('Có giao dịch mới'), findsOneWidget);
    expect(find.text('Hoạt động'), findsNothing);
  });

  testWidgets('GroupDetailScreen bấm hoạt động nhóm mở activity center', (
    tester,
  ) async {
    final groupRepository = FakeGroupRepository(
      notifications: [
        GroupNotification(
          id: 'notification-1',
          groupId: 'group-1',
          groupName: 'Group',
          type: 'transaction_posted',
          isRead: false,
          createdAt: DateTime(2026, 7, 1),
          groupTransactionId: 'transaction-1',
        ),
      ],
    );

    await tester.pumpWidget(
      groupRouterApp(
        groupRepository: groupRepository,
        initialLocation: GroupDetailScreen.routePath,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hoạt động nhóm').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hoạt động'), findsOneWidget);
    expect(find.text('Thông báo'), findsOneWidget);

    await tester.tap(find.text('Thông báo'));
    await tester.pumpAndSettle();

    expect(find.text('Có giao dịch mới'), findsOneWidget);
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
    List<GroupNotification>? notifications,
  }) : members = members ?? const [],
       directInvites = [...?directInvites],
       notifications = [...?notifications];

  final List<SpendingGroupMember> members;
  final List<String> invitedUserIds = [];
  final List<GroupDirectInvite> directInvites;
  final List<GroupNotification> notifications;
  final List<String> declinedInviteIds = [];

  @override
  Future<GroupBudget> fetchBudget(String groupId) async =>
      GroupBudget.defaults(groupId);

  @override
  Future<void> saveBudget(GroupBudget budget) async {}

  @override
  Future<GroupMonthlyStats> fetchMonthlyStats({
    required String groupId,
    required DateTime month,
  }) async => GroupMonthlyStats(
    groupId: groupId,
    month: month,
    totalSpent: 0,
    transactionCount: 0,
    topCategoryName: null,
    topCategoryAmount: 0,
    categoryBreakdown: const [],
    memberBreakdown: const [],
  );

  @override
  Future<List<GroupSettlementHistoryEntry>> fetchSettlementHistory(
    String groupId,
  ) async => const [];

  @override
  Future<void> markAllNotificationsRead() async {}

  @override
  Future<GroupNotificationPreference> fetchNotificationPreference(
    String groupId,
  ) async => GroupNotificationPreference.defaults(groupId);

  @override
  Future<void> saveNotificationPreference(
    GroupNotificationPreference preference,
  ) async {}

  @override
  Future<GroupPublicProfile> fetchGroupPublicProfile(String groupId) async =>
      GroupPublicProfile.defaults(groupId);

  @override
  Future<void> saveGroupPublicProfile(GroupPublicProfile profile) async {}

  @override
  Future<GroupPublicProfile> fetchPublicGroupProfile(String slug) async =>
      GroupPublicProfile.defaults('public-group');

  @override
  Future<List<GroupAuditLog>> fetchAuditLogs(String groupId) async => const [];

  @override
  Future<List<GroupPoll>> fetchPolls(String groupId) async => const [];

  @override
  Future<String> createPoll({
    required String groupId,
    required String title,
    required List<String> options,
  }) async => 'mock-poll';

  @override
  Future<void> votePoll({
    required String pollId,
    required String optionId,
  }) async {}

  @override
  Future<List<GroupSavingsChallenge>> fetchSavingsChallenges(
    String groupId,
  ) async => const [];

  @override
  Future<String> createSavingsChallenge({
    required String groupId,
    required String title,
    required int targetAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async => 'mock-challenge';

  @override
  Future<void> addSavingsContribution({
    required String challengeId,
    required int amount,
    String? note,
  }) async {}

  @override
  Future<GroupTransactionPage> fetchTransactionsPage({
    required String groupId,
    required int offset,
    required int limit,
    String query = '',
    String? status,
  }) async => const GroupTransactionPage(items: [], hasMore: false);

  @override
  Future<List<GroupRecurringTransaction>> fetchRecurringTransactions(
    String groupId,
  ) async => const [];

  @override
  Future<String> createRecurringTransaction({
    required String groupId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    bool autoPost = false,
  }) async => 'mock-recurring-id';

  @override
  Future<void> updateRecurringTransaction({
    required String id,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextRunAt,
    required int notifyDaysBefore,
    required bool isActive,
    bool autoPost = false,
  }) async {}

  @override
  Future<void> deleteRecurringTransaction(String id) async {}

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
  Future<void> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? type,
  }) async {}

  @override
  Future<void> setGroupArchived({
    required String groupId,
    required bool archived,
  }) async {}

  @override
  Future<void> updateGroupAvatar({
    required String groupId,
    required String filePath,
  }) async {}

  @override
  Future<void> updateGroupCurrency({
    required String groupId,
    required String baseCurrency,
  }) async {}

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
  Future<GroupSettlementOverview> fetchSettlementOverview(
    String groupId,
  ) async {
    return GroupSettlementOverview(
      balances: [
        GroupBalance(
          groupId: groupId,
          userId: currentUserId,
          totalShareAmount: 0,
          totalPaidAmount: 0,
          balance: 0,
          displayName: 'Mock User',
        ),
      ],
      suggestions: const [],
    );
  }

  @override
  Future<GroupTransactionDetail> fetchTransactionDetail(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupTransaction>> fetchTransactions(String groupId) async =>
      const [];

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
  Future<void> disputeSettlement({
    required String settlementId,
    required String reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMember({required String groupId, required String userId}) {
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
  Future<List<GroupReactionSummary>> fetchReactions(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<void> toggleReaction({
    required String transactionId,
    required String emoji,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<GroupActivity>> fetchActivities(String groupId) async => const [];

  @override
  Future<List<GroupNotification>> fetchNotifications({
    String? category,
  }) async => category == null
      ? notifications
      : notifications.where((item) => item.category == category).toList();

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      return;
    }
    final notification = notifications[index];
    notifications[index] = GroupNotification(
      id: notification.id,
      groupId: notification.groupId,
      groupName: notification.groupName,
      type: notification.type,
      isRead: true,
      createdAt: notification.createdAt,
      groupTransactionId: notification.groupTransactionId,
      inviteToken: notification.inviteToken,
      category: notification.category,
    );
  }
}
