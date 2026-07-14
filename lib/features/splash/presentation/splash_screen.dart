import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../shared/brand/brand_assets.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/application/post_auth_decision_provider.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../../profile/presentation/profile_survey_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minimumVisibleDuration = Duration(milliseconds: 1200);

  final DateTime _shownAt = DateTime.now();
  bool _isNavigated = false;

  Future<void> _navigateTo(String routePath) async {
    if (_isNavigated || !mounted) return;

    _isNavigated = true;
    final remaining =
        _minimumVisibleDuration - DateTime.now().difference(_shownAt);
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) return;
    context.go(routePath);
  }

  @override
  Widget build(BuildContext context) {
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    final decisionAsync = ref.watch(postAuthDecisionProvider);
    final colors = context.moniaryColors;

    ref.listen(postAuthDecisionProvider, (previous, next) {
      if (_isNavigated || !mounted) return;

      next.whenData((decision) {
        if (!onboardingSeen) {
          unawaited(_navigateTo(OnboardingScreen.routePath));
          return;
        }

        switch (decision.destination) {
          case PostAuthDestination.profileSetup:
            unawaited(_navigateTo(ProfileSetupScreen.routePath));
          case PostAuthDestination.profileSurvey:
            unawaited(_navigateTo(ProfileSurveyScreen.routePath));
          case PostAuthDestination.home:
            unawaited(_navigateTo(CalendarScreen.routePath));
          case PostAuthDestination.pendingDeletion:
          case PostAuthDestination.noSession:
            unawaited(_navigateTo(LoginScreen.routePath));
        }
      });
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF2E3),
              AppTheme.backgroundSoft,
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const _SplashLogo(size: 168),
                const SizedBox(height: 22),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.splashSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.splashDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                ),
                const Spacer(),
                if (decisionAsync.hasError)
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
                          ref.invalidate(postAuthDecisionProvider);
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
                      color: colors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colors.outline),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_back_outlined,
                          color: AppTheme.terracotta,
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
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: AppTheme.terracotta.withValues(alpha: 0.2),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        BrandAssets.appLogo,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
