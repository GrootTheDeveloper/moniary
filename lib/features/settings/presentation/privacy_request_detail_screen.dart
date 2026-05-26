import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../application/account_actions_controller.dart';
import '../domain/privacy_request_history_entry.dart';
import '../domain/privacy_request_sla.dart';

class PrivacyRequestDetailScreen extends ConsumerWidget {
  const PrivacyRequestDetailScreen({required this.entry, super.key});

  static const routePath = '/privacy-request-detail';

  final PrivacyRequestHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(privacyRequestHistoryProvider);
    final actionState = ref.watch(accountActionsControllerProvider);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _DetailHero(entry: currentEntry, createdAt: createdAt),
                const SizedBox(height: 16),
                _DueDateTile(dueDate: dueDate),
                const SizedBox(height: 12),
                _StatusTile(
                  label: status.label,
                  description: status.description,
                ),
                const SizedBox(height: 12),
                _StatusActions(
                  entry: currentEntry,
                  isBusy: actionState.isLoading,
                  onStatusChange: (status) {
                    ref
                        .read(accountActionsControllerProvider.notifier)
                        .updatePrivacyRequestStatus(
                          id: currentEntry.id,
                          status: status,
                        );
                  },
                ),
                const SizedBox(height: 12),
                _DetailTile(
                  icon: Icons.notes_outlined,
                  title: 'Nội dung yêu cầu',
                  value: currentEntry.message.trim().isEmpty
                      ? 'Không có nội dung bổ sung.'
                      : currentEntry.message.trim(),
                ),
                _DetailTile(
                  icon: Icons.folder_outlined,
                  title: 'File đã tạo',
                  value: currentEntry.path,
                ),
              ],
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
            entry.requestType,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo lúc $createdAt',
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
                  'Dự kiến phản hồi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '$dueDate hoặc trong $privacyRequestResponseBusinessDays ngày làm việc sau khi gửi.',
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

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.entry,
    required this.isBusy,
    required this.onStatusChange,
  });

  final PrivacyRequestHistoryEntry entry;
  final bool isBusy;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final nextStatus = switch (entry.status) {
      'ready_to_send' => 'sent_manually',
      'sent_manually' => 'resolved',
      _ => null,
    };

    if (nextStatus == null) {
      return const SizedBox.shrink();
    }

    final next = privacyRequestStatusById(nextStatus);

    return OutlinedButton.icon(
      onPressed: isBusy ? null : () => onStatusChange(nextStatus),
      icon: const Icon(Icons.task_alt_outlined),
      label: Text('Đánh dấu: ${next.label}'),
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
