import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/preferences/preferences_providers.dart';

import '../../../app/app_theme.dart';
import '../../../core/deeplinks/pending_deep_link_controller.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/brand/brand_assets.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../../profile/presentation/profile_survey_screen.dart';
import '../../settings/domain/account/account_deletion_status.dart';
import '../application/account_status_controller.dart';
import '../application/auth_controller.dart';
import '../application/post_auth_decision_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRecoverySheetOpen = false;
  bool _isResolvingPostAuth = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(currentSessionProvider) != null) {
        await _completeAuthentication();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final authAction = ref.watch(authControllerProvider);
    final isBusy = authAction.isLoading || _isResolvingPostAuth;

    ref.listen(currentSessionProvider, (previous, next) {
      if (previous == null && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _completeAuthentication();
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: context.canPop()
                                ? IconButton(
                                    onPressed: context.pop,
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_outlined,
                                      size: 19,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.17,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                BrandAssets.appLogo,
                                fit: BoxFit.cover,
                                semanticLabel: context.l10n.loginTitle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isSignUp
                              ? context.l10n.loginCreateAccount
                              : context.l10n.loginHeader,
                          textAlign: TextAlign.center,
                          style: context.moniaryTypography.displaySmall,
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isBusy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.l10n.loginEmailLabel,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return context.l10n.loginEmailRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 11),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isBusy,
                          obscureText: _obscurePassword,
                          autofillHints: [
                            _isSignUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) {
                            if (!isBusy) _submitEmail();
                          },
                          decoration: InputDecoration(
                            labelText: context.l10n.loginPasswordLabel,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 6) {
                              return context.l10n.loginPasswordMinLength;
                            }
                            return null;
                          },
                        ),
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isBusy ? null : _requestPasswordReset,
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                                minimumSize: const Size(44, 44),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(context.l10n.loginForgotPassword),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        FilledButton(
                          onPressed: isBusy ? null : _submitEmail,
                          child: isBusy
                              ? SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.background,
                                  ),
                                )
                              : Text(
                                  _isSignUp
                                      ? context.l10n.loginSignUp
                                      : context.l10n.loginSignIn,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? context.l10n.loginHaveAccount
                                  : context.l10n.loginNoAccount,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: isBusy
                                  ? null
                                  : () => setState(() {
                                      _isSignUp = !_isSignUp;
                                      _formKey.currentState?.reset();
                                    }),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                _isSignUp
                                    ? context.l10n.loginSignIn
                                    : context.l10n.loginRegisterNow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _DividerLabel(label: context.l10n.loginSocialDivider),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialButton(
                              tooltip: context.l10n.loginGoogle,
                              icon: Icons.g_mobiledata_outlined,
                              onPressed: isBusy
                                  ? null
                                  : () => _enterApp(
                                      () => ref
                                          .read(authControllerProvider.notifier)
                                          .signInWithGoogle(),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            _SocialButton(
                              tooltip: context.l10n.loginFacebook,
                              icon: Icons.facebook_outlined,
                              onPressed: isBusy
                                  ? null
                                  : () => _enterApp(
                                      () => ref
                                          .read(authControllerProvider.notifier)
                                          .signInWithFacebook(),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            _SocialButton(
                              tooltip: context.l10n.loginApple,
                              icon: Icons.apple,
                              onPressed: isBusy
                                  ? null
                                  : () => _enterApp(
                                      () => ref
                                          .read(authControllerProvider.notifier)
                                          .signInWithApple(),
                                    ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        OutlinedButton(
                          key: const ValueKey('login_demo_button'),
                          onPressed: isBusy
                              ? null
                              : () => _enterApp(
                                  () => ref
                                      .read(authControllerProvider.notifier)
                                      .startDemoSession(),
                                ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: colors.primary,
                            side: BorderSide(
                              color: colors.primary.withValues(alpha: 0.5),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          child: Text(context.l10n.loginDemoCta),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          key: const ValueKey('login_guest_button'),
                          onPressed: isBusy
                              ? null
                              : () => _enterApp(
                                  () => ref
                                      .read(authControllerProvider.notifier)
                                      .signInAnonymously(),
                                ),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            minimumSize: const Size.fromHeight(48),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(context.l10n.loginGuestCta),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const ValueKey('login_reset_onboarding_dev'),
                            onPressed: () async {
                              await ref
                                  .read(onboardingSeenProvider.notifier)
                                  .reset();
                              if (context.mounted) {
                                context.go(OnboardingScreen.routePath);
                              }
                            },
                            icon: const Icon(
                              Icons.restart_alt_outlined,
                              size: 16,
                            ),
                            label: const Text('RESET ONBOARDING (DEV)'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              foregroundColor: colors.primary,
                              side: BorderSide(
                                color: colors.primary.withValues(alpha: 0.5),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .signUpWithEmail(email: email, password: password);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loginEmailConfirmationSent)),
        );
        setState(() => _isSignUp = false);
      } catch (error, stackTrace) {
        _showAuthError(error, stackTrace);
      }
      return;
    }

    await _enterApp(
      () => ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> _requestPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.loginEmailRequired)));
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginPasswordResetSent)),
      );
    } catch (error, stackTrace) {
      _showAuthError(error, stackTrace);
    }
  }

  Future<void> _enterApp(Future<void> Function() signInAction) async {
    try {
      await signInAction();
      if (!mounted) return;
      if (ref.read(currentSessionProvider) == null) {
        await _completeAuthentication();
      }
    } catch (error, stackTrace) {
      _showAuthError(error, stackTrace);
    }
  }

  void _showAuthError(Object error, StackTrace stackTrace) {
    AppLogger.error('Authentication action failed', error, stackTrace);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFriendlyMessage(context, error))),
    );
  }

  Future<void> _completeAuthentication() async {
    if (_isResolvingPostAuth) return;
    _isResolvingPostAuth = true;
    if (mounted) setState(() {});

    late final PostAuthDecision decision;
    try {
      decision = await ref.refresh(postAuthDecisionProvider.future);
    } catch (error, stackTrace) {
      AppLogger.error('Post-authentication decision failed', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
      return;
    } finally {
      _isResolvingPostAuth = false;
      if (mounted) setState(() {});
    }
    if (!mounted) return;

    switch (decision.destination) {
      case PostAuthDestination.noSession:
        return;
      case PostAuthDestination.profileSetup:
        context.go(ProfileSetupScreen.routePath);
      case PostAuthDestination.profileSurvey:
        context.go(ProfileSurveyScreen.routePath);
      case PostAuthDestination.home:
        final pendingRoute = ref
            .read(pendingDeepLinkProvider.notifier)
            .consume();
        context.go(pendingRoute ?? CalendarScreen.routePath);
      case PostAuthDestination.pendingDeletion:
        await _showRecoverySheet(decision.deletionStatus!);
    }
  }

  Future<void> _showRecoverySheet(AccountDeletionStatus status) async {
    if (_isRecoverySheetOpen || !mounted) return;
    _isRecoverySheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (sheetContext) => PopScope(
        canPop: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.restore_outlined,
                size: 48,
                color: AppTheme.terracotta,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.restoreAccountTitle,
                textAlign: TextAlign.center,
                style: context.moniaryTypography.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.restoreAccountPendingBody(
                  _formatDate(status.deletedAt),
                  _formatDate(status.scheduledDeletionAt),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _restoreAccount(sheetContext),
                icon: const Icon(Icons.restore_outlined),
                label: Text(context.l10n.restoreAccountButton),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _signOutPendingAccount(sheetContext),
                icon: const Icon(Icons.logout_outlined),
                label: Text(context.l10n.profileSignOut),
              ),
            ],
          ),
        ),
      ),
    );
    _isRecoverySheetOpen = false;
  }

  Future<void> _restoreAccount(BuildContext sheetContext) async {
    await ref.read(accountStatusControllerProvider.notifier).restoreAccount();
    final restoreState = ref.read(accountStatusControllerProvider);
    if (!mounted) return;
    if (restoreState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyMessage(context, restoreState.error!)),
        ),
      );
      return;
    }
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    ref.invalidate(currentProfileProvider);
    await _completeAuthentication();
  }

  Future<void> _signOutPendingAccount(BuildContext sheetContext) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (mounted) context.go(LoginScreen.routePath);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return context.l10n.commonUnknown;
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final divider = colors.textPrimary.withValues(alpha: 0.12);

    return Row(
      children: [
        Expanded(child: Divider(color: divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textDim),
          ),
        ),
        Expanded(child: Divider(color: divider, height: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 24),
      color: colors.textPrimary,
      disabledColor: colors.textDim.withValues(alpha: 0.45),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor: colors.surface.withValues(alpha: 0.72),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.8)),
        shape: const CircleBorder(),
      ),
    );
  }
}
