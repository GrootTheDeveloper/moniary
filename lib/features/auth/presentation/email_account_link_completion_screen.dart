import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../settings/presentation/profile_screen.dart';
import '../application/auth_controller.dart';
import '../application/pending_email_link_controller.dart';

class EmailAccountLinkCompletionScreen extends ConsumerStatefulWidget {
  const EmailAccountLinkCompletionScreen({super.key});

  static const routePath = '/complete-email-account-link';

  @override
  ConsumerState<EmailAccountLinkCompletionScreen> createState() =>
      _EmailAccountLinkCompletionScreenState();
}

class _EmailAccountLinkCompletionScreenState
    extends ConsumerState<EmailAccountLinkCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final pendingLink = ref.watch(pendingEmailAccountLinkProvider);
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.routeGoBack,
          onPressed: authState.isLoading
              ? null
              : () => context.go(ProfileScreen.routePath),
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: Text(context.l10n.emailLinkCompleteTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: pendingLink == null
                  ? _MissingLinkState(
                      onReturn: () => context.go(ProfileScreen.routePath),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 56,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.emailLinkCompleteTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.emailLinkCompleteSubtitle(
                              pendingLink.email,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            key: const ValueKey('email_link_password'),
                            controller: _passwordController,
                            enabled: !authState.isLoading,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: context.l10n.profileNewPassword,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').length < 6) {
                                return context.l10n.validationPasswordMinLength(
                                  6,
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('email_link_confirm'),
                            controller: _confirmPasswordController,
                            enabled: !authState.isLoading,
                            obscureText: _obscureConfirmation,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!authState.isLoading) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: context.l10n.confirmPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscureConfirmation =
                                      !_obscureConfirmation,
                                ),
                                icon: Icon(
                                  _obscureConfirmation
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return context.l10n.validationPasswordsMismatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: const ValueKey('email_link_submit'),
                            onPressed: authState.isLoading ? null : _submit,
                            child: authState.isLoading
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.background,
                                    ),
                                  )
                                : Text(context.l10n.emailLinkCompleteSubmit),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeEmailAccountLink(password: _passwordController.text);
      if (!mounted) return;
      context.go(ProfileScreen.routePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.profileLinkSuccess)));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to complete email account link',
        error,
        stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _MissingLinkState extends StatelessWidget {
  const _MissingLinkState({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.link_off_outlined, size: 56),
        const SizedBox(height: 16),
        Text(
          context.l10n.emailLinkMissing,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: onReturn,
          child: Text(context.l10n.emailLinkReturnProfile),
        ),
      ],
    );
  }
}
