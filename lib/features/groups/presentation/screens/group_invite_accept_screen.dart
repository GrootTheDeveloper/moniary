import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community.dart';
import '../groups_screen.dart';
import 'group_detail_screen.dart';

class GroupInviteAcceptScreen extends ConsumerWidget {
  const GroupInviteAcceptScreen({required this.token, super.key});

  static const routePath = '/groups/invite/accept/:token';

  static String routeLocation(String token) {
    return '/groups/invite/accept/${Uri.encodeComponent(token)}';
  }

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(groupInvitePreviewProvider(token));
    final action = ref.watch(groupActionControllerProvider);

    ref.listen(groupActionControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupInviteAcceptTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: previewAsync.when(
            loading: () => _MessageState(
              icon: Icons.group_add_outlined,
              title: context.l10n.groupInviteLoading,
            ),
            error: (error, stackTrace) {
              AppLogger.error(
                'Failed to load group invite preview',
                error,
                stackTrace,
              );
              return _MessageState(
                icon: Icons.link_off_outlined,
                title: context.l10n.groupInvitePreviewError,
                action: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(groupInvitePreviewProvider(token)),
                  child: Text(context.l10n.retry),
                ),
              );
            },
            data: (preview) => _InviteBody(
              preview: preview,
              actionLoading: action.isLoading,
              onAccept: () => _accept(context, ref),
              onDecline: () => _decline(context, ref),
              onOpenGroups: () => context.go(GroupsScreen.routePath),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(groupActionControllerProvider.notifier)
          .acceptInvite(token);
      if (!context.mounted) return;
      final message = result.status == GroupInviteAcceptStatus.alreadyMember
          ? context.l10n.groupInviteAlreadyMember
          : context.l10n.groupInviteAccepted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      final groupId = result.groupId;
      if (groupId == null) {
        context.go(GroupsScreen.routePath);
        return;
      }
      context.go(GroupDetailScreen.routePath, extra: groupId);
    } catch (_) {
      // The listener above maps AppException codes to localized SnackBars.
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .declineInvite(token);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupInviteDeclined)));
      context.go(GroupsScreen.routePath);
    } catch (_) {
      // The listener above maps AppException codes to localized SnackBars.
    }
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({
    required this.preview,
    required this.actionLoading,
    required this.onAccept,
    required this.onDecline,
    required this.onOpenGroups,
  });

  final GroupInvitePreview preview;
  final bool actionLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    if (!preview.canAccept) {
      return _MessageState(
        icon: _statusIcon(preview.status),
        title: _statusMessage(context, preview.status),
        action: FilledButton(
          onPressed: onOpenGroups,
          child: Text(context.l10n.groupInviteOpenGroups),
        ),
        child: preview.groupName == null ? null : _GroupSummary(preview),
      );
    }

    final groupName = preview.groupName ?? context.l10n.groupTitle;
    final inviter = preview.inviterName ?? context.l10n.groupUnknownMember;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.groups_2_outlined, color: AppTheme.mint, size: 64),
        const SizedBox(height: 20),
        Text(
          context.l10n.groupInviteAcceptTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.groupInviteAcceptSubtitle(groupName, inviter),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        _GroupSummary(preview),
        const Spacer(),
        FilledButton.icon(
          onPressed: actionLoading ? null : onAccept,
          icon: actionLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add_outlined),
          label: Text(context.l10n.groupInviteAcceptButton),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: actionLoading ? null : onDecline,
          child: Text(context.l10n.groupInviteDeclineButton),
        ),
      ],
    );
  }

  String _statusMessage(BuildContext context, GroupInviteStatus status) {
    switch (status) {
      case GroupInviteStatus.pending:
        return context.l10n.groupInviteAcceptTitle;
      case GroupInviteStatus.accepted:
        return context.l10n.groupInviteAlreadyAccepted;
      case GroupInviteStatus.declined:
        return context.l10n.groupInviteDeclinedStatus;
      case GroupInviteStatus.expired:
        return context.l10n.groupInviteExpired;
      case GroupInviteStatus.invalid:
        return context.l10n.groupInviteInvalid;
      case GroupInviteStatus.alreadyMember:
        return context.l10n.groupInviteAlreadyMember;
      case GroupInviteStatus.groupArchived:
        return context.l10n.groupInviteGroupArchived;
    }
  }

  IconData _statusIcon(GroupInviteStatus status) {
    switch (status) {
      case GroupInviteStatus.alreadyMember:
      case GroupInviteStatus.accepted:
        return Icons.groups_2_outlined;
      case GroupInviteStatus.declined:
      case GroupInviteStatus.expired:
      case GroupInviteStatus.invalid:
      case GroupInviteStatus.groupArchived:
      case GroupInviteStatus.pending:
        return Icons.link_off_outlined;
    }
  }
}

class _GroupSummary extends StatelessWidget {
  const _GroupSummary(this.preview);

  final GroupInvitePreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SupabaseImage(
            imagePath: preview.avatarPath,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(18),
            fallbackIcon: Icons.groups_2_outlined,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.groupName ?? context.l10n.groupTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(context.l10n.groupInviteMemberCount(preview.memberCount)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 64, color: AppTheme.mintSoft),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (child != null) ...[const SizedBox(height: 20), child!],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}
