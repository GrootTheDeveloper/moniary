import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/privacy_controller.dart';
import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  static const routePath = '/app-lock';

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAuth();
    });
  }

  Future<void> _promptAuth() async {
    await ref.read(privacyControllerProvider.notifier).authenticateUser(context.l10n.biometricReasonUnlock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: AppTheme.mint),
            const SizedBox(height: 24),
            Text(
              context.l10n.appLockTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.appLockSubtitle,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _promptAuth,
              icon: const Icon(Icons.fingerprint),
              label: Text(context.l10n.appLockUnlockButton),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.mint,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
