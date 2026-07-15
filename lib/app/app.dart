import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/deeplinks/app_deep_link.dart';
import '../core/deeplinks/pending_deep_link_controller.dart';
import '../core/preferences/preferences_providers.dart';
import '../core/notifications/notification_providers.dart';
import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/settings/presentation/privacy/app_lock_screen.dart';
import '../l10n/gen_l10n/app_localizations.dart';
import '../shared/utils/app_logger.dart';
import 'app_router.dart';
import 'app_theme.dart';
import '../features/settings/application/privacy_controller.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/presentation/screens/notification_center_screen.dart';

class MoniaryApp extends ConsumerStatefulWidget {
  const MoniaryApp({super.key});

  @override
  ConsumerState<MoniaryApp> createState() => _MoniaryAppState();
}

class _MoniaryAppState extends ConsumerState<MoniaryApp>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  ProviderSubscription? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionSubscription = ref.listenManual(currentSessionProvider, (
      previous,
      next,
    ) {
      if (next == null && previous != null) {
        unawaited(ref.read(fcmPushNotificationServiceProvider).reset());
      } else if (next != null && previous?.user.id != next.user.id) {
        unawaited(_initializePushNotifications());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
      _initializePushNotifications();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(appRouterProvider),
      locale: Locale(ref.watch(preferredLocaleProvider)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Future<void> _initializeDeepLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to read initial app link', error, stackTrace);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('Failed to handle app link', error, stackTrace);
      },
    );
  }

  void _handleDeepLink(Uri uri) {
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

      router.go(routeLocation);
      return;
    }

    ref.read(pendingDeepLinkProvider.notifier).set(routeLocation);
    router.go(LoginScreen.routePath);
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
          ref
              .read(pendingDeepLinkProvider.notifier)
              .set(NotificationCenterScreen.routePath);
          router.go(AppLockScreen.routePath);
          return;
        }
        router.go('/notifications');
      },
    );
  }
}
