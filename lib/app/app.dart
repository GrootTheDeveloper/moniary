import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/preferences/preferences_providers.dart';
import '../core/deeplinks/app_deep_link.dart';
import '../core/deeplinks/pending_deep_link_controller.dart';
import '../core/notifications/notification_providers.dart';
import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_reset_screen.dart';
import '../features/auth/application/pending_email_link_controller.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/application/pending_google_link_controller.dart';
import '../features/auth/presentation/email_account_link_completion_screen.dart';
import '../features/calendar/presentation/month/calendar_screen.dart';
import '../features/friends/presentation/widgets/friend_invite_prompt_host.dart';
import '../features/settings/presentation/privacy/app_lock_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../l10n/gen_l10n/app_localizations.dart';
import '../shared/utils/app_logger.dart';
import 'app_router.dart';
import 'app_theme.dart';
import '../features/settings/application/privacy_controller.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';

class MoniaryApp extends ConsumerStatefulWidget {
  const MoniaryApp({super.key});

  @override
  ConsumerState<MoniaryApp> createState() => _MoniaryAppState();
}

class _MoniaryAppState extends ConsumerState<MoniaryApp>
    with WidgetsBindingObserver {
  static const _nativeDeepLinks = MethodChannel('moniary/deep_links');

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _lastHandledDeepLink;
  DateTime? _lastHandledDeepLinkAt;
  ProviderSubscription? _sessionSubscription;
  bool _isCompletingGoogleLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionSubscription = ref.listenManual(currentSessionProvider, (
      previous,
      next,
    ) {
      if (next != null) unawaited(_initializePushNotifications());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
      _initializePushNotifications();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _nativeDeepLinks.setMethodCallHandler(null);
    _sessionSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(privacyControllerProvider.notifier).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.event != AuthChangeEvent.passwordRecovery) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(appRouterProvider).go(PasswordResetScreen.routePath);
        });
      });
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        final pendingLink = ref.read(pendingGoogleAccountLinkProvider);
        final user = authState.session?.user;
        if (pendingLink == null || user == null) return;
        final hasGoogleIdentity =
            user.identities?.any((identity) => identity.provider == 'google') ??
            false;
        if (!pendingLink.matches(
          userId: user.id,
          hasGoogleIdentity: hasGoogleIdentity,
        )) {
          return;
        }
        unawaited(_completePendingGoogleLink());
      });
    });

    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        final pendingLink = ref.read(pendingEmailAccountLinkProvider);
        final user = authState.session?.user;
        if (pendingLink == null || user == null) return;
        if (!pendingLink.matches(
          userId: user.id,
          email: user.email,
          isAnonymous: user.isAnonymous,
        )) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref
              .read(appRouterProvider)
              .go(EmailAccountLinkCompletionScreen.routePath);
        });
      });
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
      locale: Locale(ref.watch(preferredLocaleProvider)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          FriendInvitePromptHost(child: child ?? const SizedBox.shrink()),
    );
  }

  Future<void> _completePendingGoogleLink() async {
    if (_isCompletingGoogleLink) return;
    _isCompletingGoogleLink = true;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .completePendingGoogleAccountLink();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to complete Google account link',
        error,
        stackTrace,
      );
    } finally {
      _isCompletingGoogleLink = false;
    }
    if (!mounted) return;
    ref.read(appRouterProvider).go(ProfileScreen.routePath);
  }

  Future<void> _initializeDeepLinks() async {
    _nativeDeepLinks.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        _handleDeepLinkValue(call.arguments);
      }
    });

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('Failed to handle app link', error, stackTrace);
      },
    );

    try {
      await _handleNativeDeepLinkMethod('getInitialLink');
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
      await _handleNativeDeepLinkMethod('getLatestLink');
      final latestLink = await _appLinks.getLatestLink();
      if (latestLink != null) {
        _handleDeepLink(latestLink);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to read initial app link', error, stackTrace);
    }
  }

  Future<void> _handleNativeDeepLinkMethod(String method) async {
    try {
      final link = await _nativeDeepLinks.invokeMethod<String>(method);
      _handleDeepLinkValue(link);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to read native deep link', error, stackTrace);
    }
  }

  void _handleDeepLinkValue(Object? value) {
    if (value is! String || value.trim().isEmpty) return;
    final uri = Uri.tryParse(value.trim());
    if (uri != null) _handleDeepLink(uri);
  }

  void _handleDeepLink(Uri uri) {
    if (_isDuplicateDeepLink(uri)) return;
    final deepLink = AppDeepLink.parse(uri);
    if (deepLink == null) return;

    final routeLocation = deepLink.routeLocation;
    final router = ref.read(appRouterProvider);
    final hasSession = ref.read(currentSessionProvider) != null;
    if (hasSession) {
      final privacyState = ref.read(privacyControllerProvider);
      if (privacyState.isAppLocked && !privacyState.isAuthenticated) {
        ref.read(pendingDeepLinkProvider.notifier).set(routeLocation);
        router.go(AppLockScreen.routePath);
        return;
      }

      if (deepLink is FriendInviteDeepLink) {
        ref
            .read(pendingFriendInvitePromptProvider.notifier)
            .set(deepLink.token);
        final currentPath = router.routeInformationProvider.value.uri.path;
        if (_isAuthOrSetupPath(currentPath)) {
          router.go(CalendarScreen.routePath);
        }
        return;
      }

      router.go(routeLocation);
      return;
    }

    ref.read(pendingDeepLinkProvider.notifier).set(routeLocation);
    router.go(LoginScreen.routePath);
  }

  bool _isDuplicateDeepLink(Uri uri) {
    final now = DateTime.now();
    final lastUri = _lastHandledDeepLink;
    final lastHandledAt = _lastHandledDeepLinkAt;
    _lastHandledDeepLink = uri;
    _lastHandledDeepLinkAt = now;
    return lastUri?.toString() == uri.toString() &&
        lastHandledAt != null &&
        now.difference(lastHandledAt) < const Duration(seconds: 1);
  }

  bool _isAuthOrSetupPath(String path) {
    return path == SplashScreen.routePath ||
        path == LoginScreen.routePath ||
        path == '/onboarding' ||
        path == '/profile-setup' ||
        path == '/profile-survey';
  }

  Future<void> _initializePushNotifications() async {
    if (ref.read(useMockDataModeProvider) ||
        ref.read(currentSessionProvider) == null) {
      return;
    }
    final service = ref.read(fcmPushNotificationServiceProvider);
    await service.initialize(
      onToken: (token) => ref
          .read(notificationRepositoryProvider)
          .registerDevice(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
            locale: ref.read(preferredLocaleProvider),
            timezone: AppConstants.defaultTimezone,
          ),
      onTap: (_) async {
        // The inbox is the safe fallback when a push arrives before auth or
        // app-lock routing has completed. The in-app tile then opens the
        // exact Group/Friends target with the normal repository boundary.
        final router = ref.read(appRouterProvider);
        if (ref.read(currentSessionProvider) == null) {
          router.go(LoginScreen.routePath);
          return;
        }
        final privacyState = ref.read(privacyControllerProvider);
        if (privacyState.isAppLocked && !privacyState.isAuthenticated) {
          router.go(AppLockScreen.routePath);
          return;
        }
        router.go('/notifications');
      },
    );
  }
}
