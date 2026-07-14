import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n_extension.dart';

Future<String?> showAnonymousCaptchaDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AnonymousCaptchaDialog(),
  );
}

class _AnonymousCaptchaDialog extends StatefulWidget {
  const _AnonymousCaptchaDialog();

  @override
  State<_AnonymousCaptchaDialog> createState() =>
      _AnonymousCaptchaDialogState();
}

class _AnonymousCaptchaDialogState extends State<_AnonymousCaptchaDialog> {
  String? _captchaToken;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final locale = Localizations.localeOf(context).languageCode;
    final turnstileTheme = Theme.of(context).brightness == Brightness.dark
        ? TurnstileTheme.dark
        : TurnstileTheme.light;

    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: Text(context.l10n.anonymousCaptchaTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.anonymousCaptchaDescription,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: CloudflareTurnstile(
              siteKey: AppConstants.turnstileSiteKey,
              baseUrl: AppConstants.turnstileBaseUrl,
              action: 'anonymous_sign_in',
              options: TurnstileOptions(
                language: locale,
                theme: turnstileTheme,
                size: TurnstileSize.compact,
              ),
              onTokenReceived: (token) {
                if (!mounted) return;
                setState(() {
                  _captchaToken = token;
                  _errorMessage = null;
                });
              },
              onTokenExpired: () {
                if (!mounted) return;
                setState(() {
                  _captchaToken = null;
                  _errorMessage = context.l10n.anonymousCaptchaExpired;
                });
              },
              onError: (_) {
                if (!mounted) return;
                setState(() {
                  _captchaToken = null;
                  _errorMessage = context.l10n.anonymousCaptchaFailed;
                });
              },
              onTimeout: () {
                if (!mounted) return;
                setState(() {
                  _captchaToken = null;
                  _errorMessage = context.l10n.anonymousCaptchaTimeout;
                });
              },
            ),
          ),
          if (_captchaToken != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: colors.success,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.l10n.anonymousCaptchaVerified,
                    style: TextStyle(color: colors.success),
                  ),
                ),
              ],
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.danger),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _captchaToken == null
              ? null
              : () => Navigator.of(context).pop(_captchaToken),
          child: Text(context.l10n.commonContinue),
        ),
      ],
    );
  }
}
