import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/application/post_auth_decision_provider.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../profile/presentation/profile_setup_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    if (!mounted) {
      return;
    }

    try {
      final onboardingSeen = ref.read(onboardingSeenProvider);
      if (!onboardingSeen) {
        context.go(OnboardingScreen.routePath);
        return;
      }

      final session = ref.read(currentSessionProvider);
      if (session == null) {
        context.go(LoginScreen.routePath);
        return;
      }

      final PostAuthDecision decision;
      try {
        decision = await ref.refresh(postAuthDecisionProvider.future);
      } catch (e, st) {
        AppLogger.error('Failed to resolve existing auth session', e, st);
        await _clearBrokenSession();
        if (!mounted) return;
        context.go(LoginScreen.routePath);
        return;
      }
      if (!mounted) return;

      switch (decision.destination) {
        case PostAuthDestination.profileSetup:
          context.go(ProfileSetupScreen.routePath);
        case PostAuthDestination.home:
          context.go(CalendarScreen.routePath);
        case PostAuthDestination.pendingDeletion:
        case PostAuthDestination.noSession:
          context.go(LoginScreen.routePath);
      }
    } catch (e, st) {
      AppLogger.error('Failed to bootstrap splash flow', e, st);
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _clearBrokenSession() async {
    ref.read(mockSessionProvider.notifier).setSession(null);
    try {
      await ref.read(supabaseClientProvider).auth.signOut();
    } catch (e, st) {
      AppLogger.error('Failed to clear broken splash session', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const _SplashLogo(size: 132),
                const SizedBox(height: 22),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineLarge,
                    children: const [
                      TextSpan(
                        text: 'Mon',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'iary',
                        style: TextStyle(color: AppTheme.mint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.splashSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.splashDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                if (_hasError)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.danger,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.splashErrorConnecting,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.danger),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                          });
                          unawaited(_bootstrap());
                        },
                        child: Text(context.l10n.splashRetry),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_back_outlined,
                          color: AppTheme.amber,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.splashStarting(AppConstants.appName),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.asset('logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
