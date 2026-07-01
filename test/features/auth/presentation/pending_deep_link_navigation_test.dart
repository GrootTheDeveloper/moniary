import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/core/deeplinks/pending_deep_link_controller.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/features/auth/application/post_auth_decision_provider.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/presentation/login_screen.dart';
import 'package:moniary/features/calendar/presentation/month/calendar_screen.dart';
import 'package:moniary/features/friends/presentation/screens/friend_invite_accept_screen.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:moniary/features/profile/domain/user_profile.dart';
import 'package:moniary/features/profile/presentation/profile_setup_screen.dart';
import 'package:moniary/l10n/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session _mockSession() {
  const user = User(
    id: 'mock-user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-05-28T00:00:00Z',
  );
  return Session(
    accessToken: 'mockAccessToken',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: user,
  );
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(null, useMockData: true);

  @override
  Future<Session?> signInAnonymously() async => _mockSession();
}

class TestProfileSetupController extends ProfileSetupController {
  @override
  Future<UserProfile?> build() async {
    return const UserProfile(
      id: 'mock-user-id',
      fullName: '',
      email: 'guest@moniary.app',
      avatarUrl: null,
      loginProvider: 'anonymous',
      timezone: 'Asia/Ho_Chi_Minh',
      username: '',
    );
  }

  @override
  Future<void> saveProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? avatarImagePath,
  }) async {
    state = AsyncData(
      UserProfile(
        id: 'mock-user-id',
        fullName: fullName,
        email: 'guest@moniary.app',
        avatarUrl: avatarImagePath,
        loginProvider: 'anonymous',
        timezone: timezone,
        username: username,
      ),
    );
  }
}

Widget _routerApp({
  required ProviderContainer container,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: ProfileSetupScreen.routePath,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: CalendarScreen.routePath,
        builder: (context, state) =>
            const Scaffold(body: Text('calendar target')),
      ),
      GoRoute(
        path: FriendInviteAcceptScreen.routePath,
        builder: (context, state) =>
            Scaffold(body: Text('invite ${state.pathParameters['token']}')),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.textScaleFactorTestValue = 1;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.clearTextScaleFactorTestValue();
  });

  Future<void> useLargeTestViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('login home destination consumes pending invite route', (
    tester,
  ) async {
    await useLargeTestViewport(tester);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        postAuthDecisionProvider.overrideWith(
          (ref) async => const PostAuthDecision(PostAuthDestination.home),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(pendingDeepLinkProvider.notifier)
        .set('/friends/invite/token-1');

    await tester.pumpWidget(
      _routerApp(container: container, initialLocation: LoginScreen.routePath),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('invite token-1'), findsOneWidget);
    expect(container.read(pendingDeepLinkProvider), isNull);
  });

  testWidgets('profile setup keeps pending invite until save succeeds', (
    tester,
  ) async {
    await useLargeTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        profileSetupControllerProvider.overrideWith(
          TestProfileSetupController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(pendingDeepLinkProvider.notifier)
        .set('/friends/invite/token-2');

    await tester.pumpWidget(
      _routerApp(
        container: container,
        initialLocation: ProfileSetupScreen.routePath,
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(pendingDeepLinkProvider), '/friends/invite/token-2');

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Bee Nguyen');
    await tester.enterText(textFields.at(1), 'bee_nguyen');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('invite token-2'), findsOneWidget);
    expect(container.read(pendingDeepLinkProvider), isNull);
  });
}
