import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/deeplinks/pending_deep_link_controller.dart';
import '../../../calendar/presentation/month/calendar_screen.dart';
import '../../application/privacy_controller.dart';
import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  static const routePath = '/app-lock';

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _isAuthenticating = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAuth();
    });
  }

  Future<void> _promptAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      final didAuthenticate = await ref
          .read(privacyControllerProvider.notifier)
          .authenticateUser(context.l10n.biometricReasonUnlock);
      if (!mounted || !didAuthenticate) return;

      final pendingRoute = ref.read(pendingDeepLinkProvider.notifier).consume();
      context.go(pendingRoute ?? CalendarScreen.routePath);
    } catch (error, stackTrace) {
      AppLogger.error('Failed to unlock app', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outlined, size: 80, color: AppTheme.mint),
            const SizedBox(height: 24),
            Text(
              context.l10n.appLockTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.appLockSubtitle,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isAuthenticating ? null : _promptAuth,
              icon: const Icon(Icons.fingerprint),
              label: _isAuthenticating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.appLockUnlockButton),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.mint,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
