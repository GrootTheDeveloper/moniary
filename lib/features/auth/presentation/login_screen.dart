import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAction = ref.watch(authControllerProvider);
    final hasSession = ref.watch(currentSessionProvider) != null;

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                const _BrandLogo(size: 102),
                const SizedBox(height: 18),
                const _BrandTitle(),
                const SizedBox(height: 8),
                Text(
                  context.l10n.loginFeatureSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text(
                  context.l10n.loginHeader,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: 0.5,
                  child: _AuthButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: context.l10n.loginGoogle,
                    style: _AuthButtonStyle.light,
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: 0.5,
                  child: _AuthButton(
                    icon: Icons.apple_rounded,
                    label: context.l10n.loginApple,
                    style: _AuthButtonStyle.light,
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: 0.5,
                  child: _AuthButton(
                    icon: Icons.email_outlined,
                    label: context.l10n.loginEmail,
                    style: _AuthButtonStyle.dark,
                  ),
                ),
                const SizedBox(height: 20),
                const _OrDivider(),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: authAction.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final router = GoRouter.of(context);

                          try {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signInAnonymously();
                            final profile = await ref
                                .read(profileRepositoryProvider)
                                .fetchCurrentProfile();

                            if (!context.mounted) return;
                            router.go(
                              profile == null || profile.needsSetup
                                  ? ProfileSetupScreen.routePath
                                  : CalendarScreen.routePath,
                            );
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(userFriendlyMessage(error)),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(
                    authAction.isLoading
                        ? context.l10n.loginConnecting
                        : context.l10n.loginTryWithoutAuth,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Color(0xFF8298AA),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        hasSession
                            ? context.l10n.loginSessionReady
                            : context.l10n.loginDataSecure,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF62788C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset('logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
    );

    return RichText(
      text: TextSpan(
        style: style,
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
    );
  }
}

enum _AuthButtonStyle { light, dark }

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final _AuthButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final isLight = style == _AuthButtonStyle.light;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight ? Colors.transparent : AppTheme.outline,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(icon, color: isLight ? Colors.black : Colors.white, size: 26),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppTheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            context.l10n.loginOr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.outline)),
      ],
    );
  }
}
