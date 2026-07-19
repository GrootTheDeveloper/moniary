import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../settings/presentation/widgets/settings_action_tile.dart';
import '../../settings/presentation/widgets/settings_group_card.dart';
import '../application/bank_link_controller.dart';
import '../application/bank_sync_review_controller.dart';
import '../domain/models/bank_connection.dart';
import 'bank_link_connect_screen.dart';
import 'bank_sync_review_screen.dart';

class BankLinkListScreen extends ConsumerWidget {
  const BankLinkListScreen({super.key});

  static const routePath = '/bank-linking';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final connectionsAsync = ref.watch(bankLinkControllerProvider);
    final pendingCount = ref
        .watch(bankSyncReviewControllerProvider)
        .maybeWhen(data: (items) => items.length, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bankLinkTitle)),
      body: ColoredBox(
        color: colors.background,
        child: connectionsAsync.when(
          data: (connections) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
            children: [
              if (pendingCount > 0) ...[
                _ReviewBanner(
                  count: pendingCount,
                  onTap: () => context.push(BankSyncReviewScreen.routePath),
                ),
                const SizedBox(height: 20),
              ],
              SettingsGroupCard(
                title: context.l10n.bankLinkTitle,
                children: connections.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            context.l10n.bankLinkEmpty,
                            style: TextStyle(color: colors.textDim),
                          ),
                        ),
                      ]
                    : connections
                          .map(
                            (connection) => SettingsActionTile(
                              grouped: true,
                              icon: Icons.account_balance_outlined,
                              title: connection.institutionName,
                              subtitle: _subtitle(context, connection),
                              onTap: () => _showConnectionActions(
                                context,
                                ref,
                                connection,
                              ),
                            ),
                          )
                          .toList(),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => context.push(BankLinkConnectScreen.routePath),
                icon: const Icon(Icons.add_outlined),
                label: Text(context.l10n.bankLinkAddButton),
              ),
            ],
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                userFriendlyMessage(context, error),
                style: TextStyle(color: colors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context, BankConnection connection) {
    final status = switch (connection.status) {
      BankConnectionStatus.pending => context.l10n.bankLinkStatusPending,
      BankConnectionStatus.connected => context.l10n.bankLinkStatusConnected,
      BankConnectionStatus.error => context.l10n.bankLinkStatusError,
      BankConnectionStatus.revoked => context.l10n.bankLinkStatusRevoked,
    };
    final locale = Localizations.localeOf(context).toString();
    final synced = connection.lastSyncedAt == null
        ? context.l10n.bankLinkNeverSynced
        : context.l10n.bankLinkLastSynced(
            DateFormat(
              'dd/MM/yyyy HH:mm',
              locale,
            ).format(connection.lastSyncedAt!),
          );
    return '$status · $synced';
  }

  Future<void> _showConnectionActions(
    BuildContext context,
    WidgetRef ref,
    BankConnection connection,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: Text(context.l10n.bankLinkSyncAction),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _syncConnection(context, ref, connection);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.link_off_outlined,
                color: context.moniaryColors.danger,
              ),
              title: Text(
                context.l10n.bankLinkUnlink,
                style: TextStyle(color: context.moniaryColors.danger),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _confirmUnlink(context, ref, connection);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncConnection(
    BuildContext context,
    WidgetRef ref,
    BankConnection connection,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref
          .read(bankLinkControllerProvider.notifier)
          .syncConnection(connection.id);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.bankLinkSyncSuccess(count))),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _confirmUnlink(
    BuildContext context,
    WidgetRef ref,
    BankConnection connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.bankLinkUnlinkConfirmTitle),
        content: Text(context.l10n.bankLinkUnlinkConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.l10n.bankLinkUnlink,
              style: TextStyle(color: context.moniaryColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(bankLinkControllerProvider.notifier)
          .unlinkConnection(connection.id);
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.bankLinkReviewEntry(count),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_outlined, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
