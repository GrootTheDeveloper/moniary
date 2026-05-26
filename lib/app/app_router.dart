import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/preferences/preferences_providers.dart';
import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/settings/presentation/data_deletion_policy_screen.dart';
import '../features/settings/presentation/data_safety_screen.dart';
import '../features/settings/presentation/export_data_screen.dart';
import '../features/settings/presentation/permission_rationale_screen.dart';
import '../features/settings/presentation/privacy_center_screen.dart';
import '../features/settings/presentation/privacy_contact_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/transactions/presentation/camera_screen.dart';
import '../features/transactions/presentation/day_detail_screen.dart';
import '../features/transactions/presentation/transaction_detail_screen.dart';
import '../features/transactions/presentation/transaction_form_sheet.dart';
import '../features/transactions/presentation/transaction_route_args.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange;
  final authRefreshListenable = GoRouterRefreshStream(authStateStream);

  ref.onDispose(authRefreshListenable.dispose);

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authRefreshListenable,
    redirect: (context, state) {
      final session = ref.read(currentSessionProvider);
      final onboardingSeen = ref.read(onboardingSeenProvider);
      final location = state.matchedLocation;

      const publicRoutes = {
        SplashScreen.routePath,
        OnboardingScreen.routePath,
        LoginScreen.routePath,
        ProfileSetupScreen.routePath,
      };

      if (!onboardingSeen &&
          location != SplashScreen.routePath &&
          location != OnboardingScreen.routePath) {
        return OnboardingScreen.routePath;
      }

      if (session == null && !publicRoutes.contains(location)) {
        return LoginScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => const OnboardingScreen(),
      ),
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
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: PrivacyCenterScreen.routePath,
        builder: (context, state) => const PrivacyCenterScreen(),
      ),
      GoRoute(
        path: PrivacyContactScreen.routePath,
        builder: (context, state) => const PrivacyContactScreen(),
      ),
      GoRoute(
        path: DataSafetyScreen.routePath,
        builder: (context, state) => const DataSafetyScreen(),
      ),
      GoRoute(
        path: DataDeletionPolicyScreen.routePath,
        builder: (context, state) => const DataDeletionPolicyScreen(),
      ),
      GoRoute(
        path: ExportDataScreen.routePath,
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        path: PermissionRationaleScreen.routePath,
        builder: (context, state) => const PermissionRationaleScreen(),
      ),
      GoRoute(
        path: PrivacyPolicyScreen.routePath,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: DayDetailScreen.routePath,
        builder: (context, state) {
          final date = state.extra as DateTime? ?? DateTime.now();
          return DayDetailScreen(date: date);
        },
      ),
      GoRoute(
        path: TransactionDetailScreen.routePath,
        builder: (context, state) {
          final args = state.extra as TransactionDetailRouteArgs;
          return TransactionDetailScreen(args: args);
        },
      ),
      GoRoute(
        path: CameraScreen.routePath,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/transaction-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final imagePath = extra?['imagePath'] as String?;
          return TransactionFormScreen(initialImagePath: imagePath);
        },
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
