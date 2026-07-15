import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';

class GroupAuditLogScreen extends ConsumerWidget {
  const GroupAuditLogScreen({required this.groupId, super.key});

  static const routePath = '/group-audit-log';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(groupAuditLogsProvider(groupId));
    final body = logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(userFriendlyMessage(context, error))),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(child: Text(context.l10n.groupAuditLogEmpty));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.history_outlined),
                ),
                title: Text(log.action),
                subtitle: Text(
                  '${log.actorUserId ?? context.l10n.groupAuditSystem} · '
                  '${log.createdAt.toLocal()}',
                ),
              ),
            );
          },
        );
      },
    );
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupAuditLogTitle)),
      body: body,
    );
  }
}
