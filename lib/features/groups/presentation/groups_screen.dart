import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../application/group_controller.dart';
import '../domain/expense_group.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  static const routePath = '/groups';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groupTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, size: 28),
            onPressed: () => _createGroup(context, ref),
            tooltip: context.l10n.groupCreate,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1521), AppTheme.background, Color(0xFF08111B)],
          ),
        ),
        child: SafeArea(
          child: groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _GroupsError(
              onRetry: () => ref.invalidate(groupsControllerProvider),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return const _EmptyGroups();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: groups.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => _GroupCard(
                  group: groups[index],
                  onTap: () => context.push(
                    GroupDetailScreen.routePath,
                    extra: groups[index].id,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentSessionProvider)?.user.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupNeedLogin)));
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupCreateDialog),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.groupNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(context.l10n.commonCreate),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(groupsControllerProvider.notifier)
          .createGroup(name: name, ownerId: userId);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final ExpenseGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        leading: const CircleAvatar(
          backgroundColor: AppTheme.surfaceRaised,
          foregroundColor: AppTheme.mint,
          child: Icon(Icons.groups_2_outlined),
        ),
        title: Text(group.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          '${context.l10n.groupMemberCount(group.members.length)} • ${DateFormat('dd/MM/yyyy').format(group.createdAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_2_outlined, size: 70, color: AppTheme.mint),
            const SizedBox(height: 16),
            Text(
              context.l10n.groupEmpty,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.groupEmptySubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsError extends StatelessWidget {
  const _GroupsError({required this.onRetry});

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
