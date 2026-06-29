import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../domain/transparency/data_transparency_summary.dart';
import '../export/export_data_screen.dart';
import '../export/export_history_screen.dart';
import 'privacy_contact_screen.dart';
import '../account/delete_account_screen.dart';

class DataTransparencyScreen extends ConsumerWidget {
  const DataTransparencyScreen({super.key});

  static const routePath = '/data-transparency';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dataTransparencySummaryProvider);
    final actionState = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          AppLogger.error(
            'Failed to run data transparency action',
            error,
            stackTrace,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyMyData)),
      body: SafeArea(
        child: Stack(
          children: [
            summaryAsync.when(
              data: (summary) => _Overview(
                summary: summary,
                isBusy: actionState.isLoading,
                onDeleteAccount: actionState.isLoading
                    ? null
                    : () => context.push(DeleteAccountScreen.routePath),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                AppLogger.error(
                  'Failed to load data transparency summary',
                  error,
                  stackTrace,
                );
                return Center(child: Text(userFriendlyMessage(context, error)));
              },
            ),
            if (actionState.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.summary,
    required this.isBusy,
    required this.onDeleteAccount,
  });

  final DataTransparencySummary summary;
  final bool isBusy;
  final VoidCallback? onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          context.l10n.privacyDataOverview,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _MetricGrid(
          items: [
            _MetricItem(
              context.l10n.metricTransaction,
              summary.transactionCount.toString(),
            ),
            _MetricItem(
              context.l10n.metricWallet,
              summary.walletCount.toString(),
            ),
            _MetricItem(
              context.l10n.metricCategory,
              summary.categoryCount.toString(),
            ),
            _MetricItem(
              context.l10n.metricHasPhoto,
              summary.photoTransactionCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyDataInventory,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _InventoryTile(
          icon: Icons.person_outlined,
          title: context.l10n.inventoryProfileTitle,
          description: context.l10n.inventoryProfileDesc,
        ),
        _InventoryTile(
          icon: Icons.account_balance_wallet_outlined,
          title: context.l10n.inventoryWalletTitle,
          description: context.l10n.inventoryWalletDesc,
        ),
        _InventoryTile(
          icon: Icons.category_outlined,
          title: context.l10n.inventoryCategoryTitle,
          description: context.l10n.inventoryCategoryDesc,
        ),
        _InventoryTile(
          icon: Icons.receipt_long_outlined,
          title: context.l10n.inventoryTransactionTitle,
          description: context.l10n.inventoryTransactionDesc,
        ),
        _InventoryTile(
          icon: Icons.image_outlined,
          title: context.l10n.inventoryPhotoTitle,
          description: context.l10n.inventoryPhotoDesc,
        ),
        _InventoryTile(
          icon: Icons.notifications_none_outlined,
          title: context.l10n.inventorySettingsTitle,
          description: context.l10n.inventorySettingsDesc,
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyPhotoData,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _PhotoSummaryCard(summary: summary),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyDataFreshness,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _FreshnessCard(summary: summary),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacySensitiveData,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        const _SensitiveDataNotice(),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyLocalFiles,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _LocalFilesCard(summary: summary),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyTransparencyReport,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _TransparencyReportCard(summary: summary),
        const SizedBox(height: 22),
        Text(
          context.l10n.privacyDataControl,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _ControlShortcutTile(
          icon: Icons.file_download_outlined,
          title: context.l10n.controlExportTitle,
          description: context.l10n.controlExportDesc,
          onTap: isBusy ? null : () => context.push(ExportDataScreen.routePath),
        ),
        const SizedBox(height: 12),
        _ControlShortcutTile(
          icon: Icons.support_agent_outlined,
          title: context.l10n.controlContactTitle,
          description: context.l10n.controlContactDesc,
          onTap: isBusy
              ? null
              : () => context.push(PrivacyContactScreen.routePath),
        ),
        const SizedBox(height: 12),
        _ControlShortcutTile(
          icon: Icons.delete_forever_outlined,
          title: context.l10n.controlDeleteTitle,
          description: context.l10n.controlDeleteDesc,
          destructive: true,
          onTap: onDeleteAccount,
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: AppTheme.mint),
              ),
              const SizedBox(height: 6),
              Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final String value;
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSummaryCard extends StatelessWidget {
  const _PhotoSummaryCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.transactionCount == 0 ? 1 : summary.transactionCount;
    final ratio = summary.photoTransactionCount / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.privacyTransactionPhotos,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            color: AppTheme.mint,
            backgroundColor: AppTheme.outline,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PhotoCount(
                  label: context.l10n.metricHasPhoto,
                  value: summary.photoTransactionCount.toString(),
                ),
              ),
              Expanded(
                child: _PhotoCount(
                  label: context.l10n.metricNoPhoto,
                  value: summary.transactionWithoutPhotoCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _FreshnessCard extends StatelessWidget {
  const _FreshnessCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('dd/MM/yyyy', loc);
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', loc);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          _FreshnessRow(
            icon: Icons.history_outlined,
            label: context.l10n.freshOldestTx,
            value: _formatDate(
              context,
              summary.oldestTransactionDate,
              dateFormat,
            ),
          ),
          const Divider(height: 24),
          _FreshnessRow(
            icon: Icons.update_outlined,
            label: context.l10n.freshNewestTx,
            value: _formatDate(
              context,
              summary.newestTransactionDate,
              dateFormat,
            ),
          ),
          const Divider(height: 24),
          _FreshnessRow(
            icon: Icons.file_download_done_outlined,
            label: context.l10n.freshLatestExport,
            value: _formatDate(
              context,
              summary.latestExportDate,
              dateTimeFormat,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? value, DateFormat format) {
    if (value == null) {
      return context.l10n.privacyNoData;
    }
    return format.format(value.toLocal());
  }
}

class _FreshnessRow extends StatelessWidget {
  const _FreshnessRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class _SensitiveDataNotice extends StatelessWidget {
  const _SensitiveDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: AppTheme.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.sensitiveDataDesc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalFilesCard extends StatelessWidget {
  const _LocalFilesCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString());
    final latestExport = summary.latestExportDate == null
        ? context.l10n.localFilesNoExport
        : context.l10n.localFilesLatest(
            dateTimeFormat.format(summary.latestExportDate!.toLocal()),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_copy_outlined,
                  color: AppTheme.mint,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.localFilesExportCount(
                        summary.exportFileCount,
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestExport,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.localFilesDesc,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(ExportHistoryScreen.routePath),
              icon: const Icon(Icons.history_outlined),
              label: Text(context.l10n.privacyViewExportHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransparencyReportCard extends StatelessWidget {
  const _TransparencyReportCard({required this.summary});

  final DataTransparencySummary summary;

  @override
  Widget build(BuildContext context) {
    final photoPercent = summary.transactionCount == 0
        ? 0
        : (summary.photoTransactionCount / summary.transactionCount * 100)
              .round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reportSummaryDesc(
              summary.transactionCount,
              summary.walletCount,
              summary.categoryCount,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          _ReportLine(
            icon: Icons.image_search_outlined,
            text: context.l10n.reportPhotoDesc(photoPercent),
          ),
          const SizedBox(height: 10),
          _ReportLine(
            icon: Icons.folder_open_outlined,
            text: context.l10n.reportExportDesc(summary.exportFileCount),
          ),
          const SizedBox(height: 10),
          _ReportLine(
            icon: Icons.lock_outline,
            text: context.l10n.reportPrivacyDesc,
          ),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.mint, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ControlShortcutTile extends StatelessWidget {
  const _ControlShortcutTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.mint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: destructive ? AppTheme.danger : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_outlined, color: color),
          ],
        ),
      ),
    );
  }
}
