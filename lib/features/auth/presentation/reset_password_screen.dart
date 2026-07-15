import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/brand/brand_assets.dart';
import '../../../shared/utils/app_logger.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../application/auth_controller.dart';

/// Shown when the user arrives via a Supabase password-recovery link
/// (AuthChangeEvent.passwordRecovery). They already have a valid session
/// at this point, but their old password is still active until they set
/// a new one here.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  static const routePath = '/reset-password';

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final authAction = ref.watch(authControllerProvider);
    final isBusy = authAction.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.17),
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
                        semanticLabel: context.l10n.resetPasswordTitle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.resetPasswordTitle,
                  textAlign: TextAlign.center,
                  style: context.moniaryTypography.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.resetPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _passwordController,
                  enabled: !isBusy,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: context.l10n.profileNewPassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                const SizedBox(height: 11),
                TextFormField(
                  controller: _confirmController,
                  enabled: !isBusy,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!isBusy) _submit();
                  },
                  decoration: InputDecoration(
                    labelText: context.l10n.resetPasswordConfirmLabel,
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return context.l10n.resetPasswordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.background,
                          ),
                        )
                      : Text(context.l10n.resetPasswordSubmit),
                ),
              ],
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
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.resetPasswordSuccess)),
      );
      context.go(CalendarScreen.routePath);
    } catch (error, stackTrace) {
      AppLogger.error('Password update failed', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
