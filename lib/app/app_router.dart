import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: SplashScreen.routePath,
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
