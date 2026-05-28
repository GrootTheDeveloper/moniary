import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../auth/presentation/login_screen.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../profile/data/profile_repository.dart';
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

      final profile = await ref
          .read(profileRepositoryProvider)
          .fetchCurrentProfile();
      if (!mounted) return;

      context.go(
        profile == null || profile.needsSetup
            ? ProfileSetupScreen.routePath
            : CalendarScreen.routePath,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
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
                  'Ghi chi tiêu bằng ảnh',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chụp lại khoản chi, lưu vào lịch,\nquản lý tiền dễ như lưu kỷ niệm.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                if (_hasError)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể kết nối',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.danger),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                          });
                          unawaited(_bootstrap());
                        },
                        child: const Text('Thử lại'),
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
                            'Đang khởi động ${AppConstants.appName}...',
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
