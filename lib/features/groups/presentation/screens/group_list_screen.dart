import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../application/group_controller.dart';
import '../widgets/group_card.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  static const routePath = '/groups';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupTitle),
        actions: [
          IconButton(
            onPressed: () => _openCreateGroup(context, ref),
            tooltip: context.l10n.groupCreateNew,
            icon: const Icon(Icons.group_add_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          AppLogger.error('Failed to load groups', error, stackTrace);
          return _ErrorState(
            onRetry: () =>
                ref.read(groupsControllerProvider.notifier).refresh(),
          );
        },
        data: (groups) {
          if (groups.isEmpty) {
            return _EmptyState(onCreate: () => _openCreateGroup(context, ref));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(groupsControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupCard(
                  group: group,
                  onTap: () => context.push(
                    GroupDetailScreen.routePath,
                    extra: group.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateGroup(BuildContext context, WidgetRef ref) async {
    final groupId = await context.push<String>(CreateGroupScreen.routePath);
    ref.invalidate(groupsControllerProvider);
    if (groupId == null || !context.mounted) return;
    await context.push(GroupDetailScreen.routePath, extra: groupId);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              size: 72,
              color: AppTheme.mintSoft,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.groupEmpty,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.groupEmptySubtitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_outlined),
              label: Text(context.l10n.groupCreateNew),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.groupLoadError),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
