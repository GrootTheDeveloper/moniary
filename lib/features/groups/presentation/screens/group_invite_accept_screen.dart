import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_invite.dart';
import 'group_route_paths.dart';
import '../groups_screen.dart';

class GroupInviteAcceptScreen extends ConsumerWidget {
  const GroupInviteAcceptScreen({required this.token, super.key});

  static const routePath = '/groups/invite/:token';

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
            loading: () => _GroupInviteMessageState(
              icon: Icons.mark_email_unread_outlined,
              title: context.l10n.groupInviteLoading,
            ),
            error: (error, stackTrace) {
              AppLogger.error(
                'Failed to load group invite preview',
                error,
                stackTrace,
              );
              return _GroupInviteMessageState(
                icon: Icons.link_off_outlined,
                title: context.l10n.groupInvitePreviewError,
                action: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(groupInvitePreviewProvider(token)),
                  child: Text(context.l10n.retry),
                ),
              );
            },
            data: (preview) => _GroupInviteBody(
              preview: preview,
              actionLoading: action.isLoading,
              onAccept: () => _accept(context, ref),
              onDismiss: () => context.go(GroupsScreen.routePath),
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
      final message = result.status == GroupInviteStatus.alreadyMember
          ? context.l10n.groupInviteAlreadyMember
          : context.l10n.groupInviteAccepted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await context.push(GroupRoutePaths.home(result.groupId));
    } catch (_) {
      // The listener maps stable AppException codes to localized messages.
    }
  }
}

class _GroupInviteBody extends StatelessWidget {
  const _GroupInviteBody({
    required this.preview,
    required this.actionLoading,
    required this.onAccept,
    required this.onDismiss,
    required this.onOpenGroups,
  });

  final GroupInvitePreview preview;
  final bool actionLoading;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    if (!preview.canAccept) {
      return _GroupInviteMessageState(
        icon: _statusIcon(preview.status),
        title: _statusTitle(context, preview.status),
        action: FilledButton(
          onPressed: onOpenGroups,
          child: Text(context.l10n.groupInviteOpenGroups),
        ),
        child: _GroupInviteCard(preview: preview),
      );
    }

    final groupName = preview.groupName ?? context.l10n.groupTitle;
    final inviterName = preview.inviterName ?? context.l10n.groupTitle;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.groups_2_outlined,
            color: context.moniaryColors.primary,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.groupInviteAcceptTitle,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.groupInviteAcceptSubtitle(inviterName, groupName),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.groupInvitePreviewNotice,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.moniaryColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _GroupInviteCard(preview: preview),
          const SizedBox(height: 32),
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
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: actionLoading ? null : onDismiss,
            child: Text(context.l10n.groupInviteDismissButton),
          ),
        ],
      ),
    );
  }

  String _statusTitle(BuildContext context, GroupInviteStatus status) {
    return switch (status) {
      GroupInviteStatus.alreadyMember => context.l10n.groupInviteAlreadyMember,
      GroupInviteStatus.expired => context.l10n.groupInviteExpired,
      GroupInviteStatus.revoked => context.l10n.groupInviteRevoked,
      GroupInviteStatus.used => context.l10n.groupInviteUsed,
      GroupInviteStatus.accepted => context.l10n.groupInviteAccepted,
      GroupInviteStatus.invalid ||
      GroupInviteStatus.active => context.l10n.groupInviteInvalid,
    };
  }

  IconData _statusIcon(GroupInviteStatus status) {
    return switch (status) {
      GroupInviteStatus.alreadyMember => Icons.groups_2_outlined,
      GroupInviteStatus.accepted => Icons.check_circle_outline,
      GroupInviteStatus.active ||
      GroupInviteStatus.used ||
      GroupInviteStatus.revoked ||
      GroupInviteStatus.expired ||
      GroupInviteStatus.invalid => Icons.link_off_outlined,
    };
  }
}

class _GroupInviteCard extends StatelessWidget {
  const _GroupInviteCard({required this.preview});

  final GroupInvitePreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final groupName = preview.groupName;
    if (groupName == null || groupName.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        children: [
          SupabaseImage(
            imagePath: preview.groupAvatarPath,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(16),
            fallbackIcon: Icons.groups_2_outlined,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              groupName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupInviteMessageState extends StatelessWidget {
  const _GroupInviteMessageState({
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
          Icon(icon, size: 64, color: context.moniaryColors.primary),
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
