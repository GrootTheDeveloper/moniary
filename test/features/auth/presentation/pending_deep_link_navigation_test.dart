import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moniary/core/deeplinks/pending_deep_link_controller.dart';
import 'package:moniary/core/preferences/preferences_providers.dart';
import 'package:moniary/core/supabase/supabase_providers.dart';
import 'package:moniary/features/auth/application/post_auth_decision_provider.dart';
import 'package:moniary/features/auth/data/auth_repository.dart';
import 'package:moniary/features/auth/presentation/login_screen.dart';
import 'package:moniary/features/calendar/presentation/month/calendar_screen.dart';
import 'package:moniary/features/categories/data/repositories/category_repository.dart';
import 'package:moniary/features/categories/domain/models/category.dart';
import 'package:moniary/features/friends/presentation/screens/friend_invite_accept_screen.dart';
import 'package:moniary/features/profile/application/profile_setup_controller.dart';
import 'package:moniary/features/profile/data/profile_repository.dart';
import 'package:moniary/features/profile/domain/user_profile.dart';
import 'package:moniary/features/profile/presentation/profile_setup_screen.dart';
import 'package:moniary/features/profile/presentation/profile_survey_screen.dart';
import 'package:moniary/features/wallets/data/repositories/wallet_repository.dart';
import 'package:moniary/features/wallets/domain/models/wallet.dart';
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

class FakeProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile(
    id: 'mock-user-id',
    fullName: 'Bee Nguyen',
    email: 'guest@moniary.app',
    avatarUrl: null,
    loginProvider: 'anonymous',
    timezone: 'Asia/Ho_Chi_Minh',
    username: 'bee_nguyen',
    surveyCompleted: false,
  );

  @override
  Future<UserProfile?> fetchCurrentProfile() async => _profile;

  @override
  Future<UserProfile> upsertProfile({
    required String fullName,
    required String username,
    required String timezone,
    String? avatarImagePath,
  }) async {
    _profile = UserProfile(
      id: _profile.id,
      fullName: fullName,
      email: _profile.email,
      avatarUrl: avatarImagePath ?? _profile.avatarUrl,
      loginProvider: _profile.loginProvider,
      timezone: timezone,
      username: username,
      surveyCompleted: _profile.surveyCompleted,
    );
    return _profile;
  }

  @override
  Future<UserProfile> completeSurvey({
    required String occupation,
    required String preferredCurrency,
  }) async {
    _profile = UserProfile(
      id: _profile.id,
      fullName: _profile.fullName,
      email: _profile.email,
      avatarUrl: _profile.avatarUrl,
      loginProvider: _profile.loginProvider,
      timezone: _profile.timezone,
      username: _profile.username,
      occupation: occupation,
      preferredCurrency: preferredCurrency,
      surveyCompleted: true,
    );
    return _profile;
  }

  @override
  Future<UserProfile> completeSurveySetup({
    required String occupation,
    required String preferredCurrency,
    required String walletName,
    required double initialBalance,
  }) {
    return completeSurvey(
      occupation: occupation,
      preferredCurrency: preferredCurrency,
    );
  }

  @override
  void resetMockProfile() {}

  @override
  void setMockEmailAndProvider({
    required String email,
    required String loginProvider,
  }) {}
}

class FakeWalletRepository implements WalletRepository {
  final List<Wallet> _wallets = [
    Wallet(
      id: 'wallet-1',
      name: 'Cash',
      type: WalletType.cash,
      icon: 'wallet',
      color: '#B85C38',
      initialBalance: 0,
      isDefault: true,
      isActive: true,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  Future<List<Wallet>> fetchWallets() async => _wallets;

  @override
  Future<void> createWallet({
    required String name,
    required WalletType type,
    required double initialBalance,
    bool isDefault = false,
  }) async {
    _wallets.add(
      Wallet(
        id: 'wallet-${_wallets.length + 1}',
        name: name,
        type: type,
        icon: 'wallet',
        color: '#B85C38',
        initialBalance: initialBalance,
        isDefault: isDefault,
        isActive: true,
        createdAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> updateWallet({
    required String walletId,
    required String name,
    required WalletType type,
    required double initialBalance,
    required bool isDefault,
    required bool isActive,
  }) async {
    final index = _wallets.indexWhere((wallet) => wallet.id == walletId);
    if (index == -1) return;
    _wallets[index] = Wallet(
      id: walletId,
      name: name,
      type: type,
      icon: _wallets[index].icon,
      color: _wallets[index].color,
      initialBalance: initialBalance,
      isDefault: isDefault,
      isActive: isActive,
      createdAt: _wallets[index].createdAt,
    );
  }

  @override
  void clearMockUserData() {
    _wallets.clear();
  }
}

class FakeCategoryRepository implements CategoryRepository {
  var initializedOccupation = '';

  @override
  Future<void> ensureOccupationDefaults(String occupation) async {
    initializedOccupation = occupation;
  }

  @override
  Future<List<Category>> fetchCategories() async => const [];

  @override
  Future<void> createCategory({
    required String name,
    required TransactionType type,
  }) async {}

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required TransactionType type,
    required bool isActive,
  }) async {}

  @override
  void clearMockUserData() {}
}

Widget _routerApp({
  required ProviderContainer container,
  required String initialLocation,
  double keyboardInset = 0,
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
        path: ProfileSurveyScreen.routePath,
        builder: (context, state) => const ProfileSurveyScreen(),
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
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
        child: child!,
      ),
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

    await tester.tap(find.byKey(const ValueKey('login_guest_button')));
    await tester.pumpAndSettle();

    expect(find.text('invite token-1'), findsOneWidget);
    expect(container.read(pendingDeepLinkProvider), isNull);
  });

  testWidgets('profile setup keeps pending invite until survey succeeds', (
    tester,
  ) async {
    await useLargeTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        useMockDataModeProvider.overrideWithValue(true),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        walletRepositoryProvider.overrideWithValue(FakeWalletRepository()),
        categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
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

    expect(find.byType(ProfileSurveyScreen), findsOneWidget);
    expect(container.read(pendingDeepLinkProvider), '/friends/invite/token-2');

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('invite token-2'), findsOneWidget);
    expect(container.read(pendingDeepLinkProvider), isNull);
  });

  testWidgets('profile setup scrolls on a compact screen without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        useMockDataModeProvider.overrideWithValue(true),
        profileSetupControllerProvider.overrideWith(
          TestProfileSetupController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _routerApp(
        container: container,
        initialLocation: ProfileSetupScreen.routePath,
        keyboardInset: 220,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final submitButton = find.byType(FilledButton);
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();

    expect(submitButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
