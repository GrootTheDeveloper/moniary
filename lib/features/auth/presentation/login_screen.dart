import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/widgets/aurora_background.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../../profile/application/profile_setup_controller.dart';
import '../../profile/presentation/profile_setup_screen.dart';
import '../application/auth_controller.dart';
import '../application/account_status_controller.dart';
import '../application/post_auth_decision_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/domain/account/account_deletion_status.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRecoverySheetOpen = false;
  bool _isResolvingPostAuth = false;

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
  Widget build(BuildContext context) {
    final authAction = ref.watch(authControllerProvider);
    final hasSession = ref.watch(currentSessionProvider) != null;

    ref.listen(currentSessionProvider, (previous, next) {
      if (previous == null && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _completeAuthentication();
        });
      }
    });

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

  Future<void> _enterApp(Future<void> Function() signInAction) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await signInAction();
      if (!mounted) return;
      await _completeAuthentication();
    } catch (error, stackTrace) {
      AppLogger.error('Post-authentication decision failed', error, stackTrace);
      if (!mounted) return;
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
        onSuccess: () async {
          if (context.mounted) Navigator.of(context).pop();
          await _completeAuthentication();
        },
      ),
    );
  }

  Future<void> _completeAuthentication() async {
    if (_isResolvingPostAuth) return;
    _isResolvingPostAuth = true;
    late final PostAuthDecision decision;
    try {
      AppLogger.info('Resolving post-auth decision...');
      decision = await ref.read(postAuthDecisionProvider.future);
      AppLogger.info('Decision resolved: ${decision.destination}');
    } catch (e, st) {
      AppLogger.error('Post-authentication decision failed in resolver', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, e))),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingPostAuth = false;
        });
      }
    }
    if (!mounted) return;

    switch (decision.destination) {
      case PostAuthDestination.noSession:
        AppLogger.info('No session found, staying on login.');
        return;
      case PostAuthDestination.profileSetup:
        AppLogger.info('Navigating to Profile Setup');
        context.go(ProfileSetupScreen.routePath);
      case PostAuthDestination.home:
        AppLogger.info('Navigating to Home');
        context.go(CalendarScreen.routePath);
      case PostAuthDestination.pendingDeletion:
        AppLogger.info('Showing Recovery Sheet');
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
                size: 54,
                color: AppTheme.amber,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.restoreAccountTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
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
                icon: const Icon(Icons.restore),
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

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.onSuccess});
  final Future<void> Function() onSuccess;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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
            SnackBar(content: Text(context.l10n.loginEmailConfirmationSent)),
          );
          Navigator.pop(context);
        }
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        await widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = userFriendlyMessage(context, e));
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
                  _isSignUp
                      ? context.l10n.loginCreateAccount
                      : context.l10n.loginEmailTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: context.l10n.loginEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || v.isEmpty)
                      ? context.l10n.loginEmailRequired
                      : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: context.l10n.loginPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? context.l10n.loginPasswordMinLength
                      : null,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : () => _submit(ref),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isSignUp
                              ? context.l10n.loginSignUp
                              : context.l10n.loginSignIn,
                        ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp
                        ? context.l10n.loginAlreadyHaveAccount
                        : context.l10n.loginNeedAccount,
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
