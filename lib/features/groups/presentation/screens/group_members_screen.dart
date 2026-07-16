import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/spending_group.dart';
import 'group_route_paths.dart';

enum _MemberAction { promote, demote, transferOwnership, remove }

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final action = ref.watch(groupActionControllerProvider);
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(
        title: Text(context.l10n.groupMembersHeader),
        actions: [
          if (detailAsync.asData?.value.canInvite ?? false)
            IconButton(
              tooltip: context.l10n.groupInviteTitle,
              onPressed: () => context.push(GroupRoutePaths.invite(groupId)),
              icon: const Icon(Icons.person_add_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          if (action.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: detailAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userFriendlyMessage(context, error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () =>
                            ref.invalidate(groupDetailProvider(groupId)),
                        icon: const Icon(Icons.refresh_outlined),
                        label: Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (detail) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(groupDetailProvider(groupId));
                  await ref.read(groupDetailProvider(groupId).future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: detail.activeMembers.length + 1,
                  separatorBuilder: (_, index) => index == 0
                      ? const SizedBox(height: 14)
                      : const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _MembersSummary(detail: detail);
                    }
                    final member = detail.activeMembers[index - 1];
                    return _MemberTile(
                      detail: detail,
                      member: member,
                      currentUserId: ref.read(currentGroupUserIdProvider),
                      onAction: action.isLoading
                          ? null
                          : (value) =>
                                _handleAction(context, ref, member, value),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    SpendingGroupMember member,
    _MemberAction action,
  ) async {
    final label = switch (action) {
      _MemberAction.promote => context.l10n.groupPromoteAdminAction,
      _MemberAction.demote => context.l10n.groupDemoteMemberAction,
      _MemberAction.transferOwnership =>
        context.l10n.groupTransferOwnershipAction,
      _MemberAction.remove => context.l10n.groupRemoveMemberAction,
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: Text(
          context.l10n.groupMemberActionConfirm(member.resolvedName, label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final controller = ref.read(groupActionControllerProvider.notifier);
      switch (action) {
        case _MemberAction.promote:
          await controller.updateMemberRole(
            groupId: groupId,
            userId: member.userId,
            role: GroupRole.admin,
          );
          break;
        case _MemberAction.demote:
          await controller.updateMemberRole(
            groupId: groupId,
            userId: member.userId,
            role: GroupRole.member,
          );
          break;
        case _MemberAction.transferOwnership:
          await controller.transferOwnership(
            groupId: groupId,
            newOwnerUserId: member.userId,
          );
          break;
        case _MemberAction.remove:
          await controller.removeMember(
            groupId: groupId,
            userId: member.userId,
          );
          break;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupMemberActionDone)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _MembersSummary extends StatelessWidget {
  const _MembersSummary({required this.detail});

  final SpendingGroupDetail detail;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.moniaryColors.primary.withValues(
              alpha: 0.12,
            ),
            child: Icon(
              Icons.groups_outlined,
              color: context.moniaryColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.group.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.groupMemberCount(detail.activeMembers.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.detail,
    required this.member,
    required this.currentUserId,
    required this.onAction,
  });

  final SpendingGroupDetail detail;
  final SpendingGroupMember member;
  final String currentUserId;
  final ValueChanged<_MemberAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final actions = _actions;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        leading: SupabaseImage(
          imagePath: member.avatarPath,
          width: 44,
          height: 44,
          borderRadius: BorderRadius.circular(22),
          fallbackBuilder: (_) => CircleAvatar(
            child: Text(member.resolvedName.characters.first.toUpperCase()),
          ),
        ),
        title: Text(member.resolvedName),
        subtitle: Text(_roleLabel(context, member.role)),
        trailing: actions.isEmpty
            ? null
            : PopupMenuButton<_MemberAction>(
                tooltip: context.l10n.groupMemberActions,
                enabled: onAction != null,
                onSelected: onAction,
                itemBuilder: (_) => [
                  for (final action in actions)
                    PopupMenuItem(
                      value: action,
                      child: Text(_actionLabel(context, action)),
                    ),
                ],
                icon: const Icon(Icons.more_vert_outlined),
              ),
      ),
    );
  }

  List<_MemberAction> get _actions {
    if (member.userId == currentUserId || member.role == GroupRole.owner) {
      return const [];
    }
    if (detail.currentUserRole == GroupRole.owner) {
      return [
        if (member.role == GroupRole.member) _MemberAction.promote,
        if (member.role == GroupRole.admin) _MemberAction.demote,
        _MemberAction.transferOwnership,
        _MemberAction.remove,
      ];
    }
    if (detail.currentUserRole == GroupRole.admin &&
        member.role == GroupRole.member) {
      return const [_MemberAction.remove];
    }
    return const [];
  }

  String _actionLabel(BuildContext context, _MemberAction action) =>
      switch (action) {
        _MemberAction.promote => context.l10n.groupPromoteAdminAction,
        _MemberAction.demote => context.l10n.groupDemoteMemberAction,
        _MemberAction.transferOwnership =>
          context.l10n.groupTransferOwnershipAction,
        _MemberAction.remove => context.l10n.groupRemoveMemberAction,
      };

  String _roleLabel(BuildContext context, GroupRole role) => switch (role) {
    GroupRole.owner => context.l10n.groupRoleOwner,
    GroupRole.admin => context.l10n.groupRoleAdmin,
    GroupRole.member => context.l10n.groupRoleMember,
  };
}
