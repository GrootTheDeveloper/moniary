import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/deeplinks/pending_deep_link_controller.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../application/auth_controller.dart';
import '../../auth/data/auth_repository.dart';

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
                    icon: const Icon(Icons.arrow_back_ios_new_outlined),
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
                GestureDetector(
                  onTap: authAction.isLoading
                      ? null
                      : () => _enterApp(
                          context,
                          ref,
                          () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                        ),
                  child: _AuthButton(
                    icon: Icons.g_mobiledata_outlined,
                    label: context.l10n.loginGoogle,
                    style: _AuthButtonStyle.light,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: authAction.isLoading
                      ? null
                      : () => _enterApp(
                          context,
                          ref,
                          () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple(),
                        ),
                  child: _AuthButton(
                    icon: Icons.apple_outlined,
                    label: context.l10n.loginApple,
                    style: _AuthButtonStyle.light,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: authAction.isLoading
                      ? null
                      : () => _showEmailAuthSheet(context, ref),
                  child: _AuthButton(
                    icon: Icons.email_outlined,
                    label: context.l10n.loginEmail,
                    style: _AuthButtonStyle.dark,
                  ),
                ),
                const SizedBox(height: 20),
                const _OrDivider(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: authAction.isLoading
                      ? null
                      : () => _enterApp(
                          context,
                          ref,
                          () => ref
                              .read(authControllerProvider.notifier)
                              .signInAnonymously(),
                        ),
                  icon: const Icon(Icons.cloud_done_outlined),
                  label: Text(
                    authAction.isLoading
                        ? context.l10n.loginConnecting
                        : context.l10n.loginAnonymous,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: authAction.isLoading
                      ? null
                      : () => _enterApp(
                          context,
                          ref,
                          () => ref
                              .read(authControllerProvider.notifier)
                              .startGuestSession(),
                        ),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(context.l10n.loginTryWithoutAuth),
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

  Future<void> _enterApp(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() signInAction,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      await signInAction();
      final profile = await ref
          .read(profileRepositoryProvider)
          .fetchCurrentProfile();

      if (!context.mounted) return;
      final needsSetup = profile == null || profile.needsSetup;
      final pendingRoute = needsSetup
          ? null
          : ref.read(pendingDeepLinkProvider.notifier).consume();
      router.go(
        needsSetup
            ? ProfileSetupScreen.routePath
            : pendingRoute ?? CalendarScreen.routePath,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  void _showEmailAuthSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EmailAuthSheet(
        onSuccess: () {
          final profile = ref
              .read(profileRepositoryProvider)
              .fetchCurrentProfile();
          profile.then((p) {
            if (context.mounted) {
              final needsSetup = p == null || p.needsSetup;
              final pendingRoute = needsSetup
                  ? null
                  : ref.read(pendingDeepLinkProvider.notifier).consume();
              context.go(
                needsSetup
                    ? ProfileSetupScreen.routePath
                    : pendingRoute ?? CalendarScreen.routePath,
              );
            }
          });
        },
      ),
    );
  }
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await ref
            .read(authRepositoryProvider)
            .signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please check your email for confirmation.'),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await ref
            .read(authRepositoryProvider)
            .signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp ? 'Create Account' : 'Sign In with Email',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : () => _submit(ref),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
