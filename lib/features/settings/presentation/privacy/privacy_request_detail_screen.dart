import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../application/account/account_actions_controller.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../../domain/privacy_requests/privacy_request_sla.dart';
import '../../domain/privacy_requests/privacy_request_type.dart';
import 'utils/privacy_request_l10n.dart';

class PrivacyRequestDetailScreen extends ConsumerWidget {
  const PrivacyRequestDetailScreen({required this.entry, super.key});

  static const routePath = '/privacy-request-detail';

  final PrivacyRequestHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(privacyRequestHistoryProvider);
    final currentEntry = historyAsync.maybeWhen(
      data: (history) => history.firstWhere(
        (item) => item.id == entry.id,
        orElse: () => entry,
      ),
      orElse: () => entry,
    );
    final createdAt = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(currentEntry.createdAt);
    final dueDate = DateFormat(
      'dd/MM/yyyy',
    ).format(privacyRequestDueDate(currentEntry.createdAt));
    final status = privacyRequestStatusById(currentEntry.status);

    final path = currentEntry.path;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyRequestDetailTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (historyAsync.hasError) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.errorGeneric,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppTheme.danger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(privacyRequestHistoryProvider),
                      icon: const Icon(Icons.refresh_outlined),
                      label: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            ],
            _DetailHero(entry: currentEntry, createdAt: createdAt),
            const SizedBox(height: 16),
            _DueDateTile(dueDate: dueDate),
            const SizedBox(height: 12),
            _StatusTile(
              label: status.label(context),
              description: status.description(context),
            ),
            const SizedBox(height: 12),
            _RequestCopyActions(entry: currentEntry),
            const SizedBox(height: 12),
            _DetailTile(
              icon: Icons.notes_outlined,
              title: context.l10n.privacyDetailContentTitle,
              value: currentEntry.message.trim().isEmpty
                  ? context.l10n.privacyDetailContentEmpty
                  : currentEntry.message.trim(),
            ),
            if (currentEntry.adminNote case final response?)
              _DetailTile(
                icon: Icons.support_agent_outlined,
                title: context.l10n.privacyDetailResponseTitle,
                value: response,
              ),
            if (path != null)
              _DetailTile(
                icon: Icons.folder_outlined,
                title: context.l10n.privacyDetailFileTitle,
                value: path,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.entry, required this.createdAt});

  final PrivacyRequestHistoryEntry entry;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppTheme.mint,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            privacyRequestTypeByStoredValue(entry.requestType).label(context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.privacyDetailCreatedAt(createdAt),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_outlined, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
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

class _DueDateTile extends StatelessWidget {
  const _DueDateTile({required this.dueDate});

  final String dueDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_available_outlined, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.privacyDetailExpectedResponse,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.privacyDetailExpectedResponseDesc(
                    dueDate,
                    privacyRequestResponseBusinessDays,
                  ),
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

class _RequestCopyActions extends StatelessWidget {
  const _RequestCopyActions({required this.entry});

  final PrivacyRequestHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final path = entry.path;
    final summary =
        '${context.l10n.privacyContactRequestType}: ${privacyRequestTypeByStoredValue(entry.requestType).label(context)}\n'
        '${context.l10n.privacyContactRequestStatus}: ${privacyRequestStatusById(entry.status).label(context)}\n'
        '${context.l10n.privacyContactRequestContent}: ${entry.message.trim()}\n'
        '${entry.adminNote == null ? '' : '${context.l10n.privacyDetailResponseTitle}: ${entry.adminNote}\n'}'
        '${path != null ? '${context.l10n.privacyContactRequestFile}: $path' : ''}';

    return Column(
      children: [
        if (path != null) ...[
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.privacyCopyFilePathSuccess),
                ),
              );
            },
            icon: const Icon(Icons.folder_copy_outlined),
            label: Text(context.l10n.privacyCopyFilePath),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: summary));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.privacyCopyRequestSuccess)),
            );
          },
          icon: const Icon(Icons.content_copy_outlined),
          label: Text(context.l10n.privacyCopyRequest),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
          Icon(icon, color: AppTheme.mint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
