import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref.watch(supabaseClientProvider).auth.onAuthStateChange;
  final authRefreshListenable = GoRouterRefreshStream(
    authStateStream,
  );

  ref.onDispose(authRefreshListenable.dispose);

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authRefreshListenable,
    redirect: (context, state) {
      final session = ref.read(currentSessionProvider);
      final location = state.matchedLocation;

      if (location == SplashScreen.routePath) {
        return null;
      }

      final isLoggedIn = session != null;
      final isOnLogin = location == LoginScreen.routePath;

      if (!isLoggedIn && !isOnLogin) {
        return LoginScreen.routePath;
      }

      if (isLoggedIn && isOnLogin) {
        return CalendarScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: CalendarScreen.routePath,
        builder: (context, state) => const CalendarScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
