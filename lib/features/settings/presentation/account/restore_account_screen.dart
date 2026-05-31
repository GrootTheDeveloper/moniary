import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../auth/application/account_status_controller.dart';
import '../../../auth/application/auth_controller.dart';

class RestoreAccountScreen extends ConsumerWidget {
  const RestoreAccountScreen({super.key});

  static const routePath = '/restore-account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountStatusControllerProvider);

    ref.listen(accountStatusControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.restore_page_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.restoreAccountTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.restoreAccountBody,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref
                            .read(accountStatusControllerProvider.notifier)
                            .restoreAccount();
                      },
                icon: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restore),
                label: Text(context.l10n.restoreAccountButton),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                        if (context.mounted) context.go('/');
                      },
                icon: const Icon(Icons.logout),
                label: Text(context.l10n.profileSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
