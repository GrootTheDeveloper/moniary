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
import 'group_detail_screen.dart';

class GroupInvitationsScreen extends ConsumerWidget {
  const GroupInvitationsScreen({super.key});

  static const routePath = '/groups/invitations';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(groupDirectInvitesProvider);
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
      appBar: AppBar(title: Text(context.l10n.groupInvitationsTitle)),
      body: invitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          AppLogger.error(
            'Failed to load direct group invites',
            error,
            stackTrace,
          );
          return _InviteMessageState(
            icon: Icons.mark_email_unread_outlined,
            title: context.l10n.groupInvitationsLoadError,
            action: OutlinedButton(
              onPressed: () => ref.invalidate(groupDirectInvitesProvider),
              child: Text(context.l10n.commonRetry),
            ),
          );
        },
        data: (invites) {
          if (invites.isEmpty) {
            return _InviteMessageState(
              icon: Icons.mark_email_read_outlined,
              title: context.l10n.groupInvitationsEmpty,
              subtitle: context.l10n.groupInvitationsEmptySubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(groupDirectInvitesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              itemCount: invites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _DirectInviteCard(
                invite: invites[index],
                isLoading: action.isLoading,
                onAccept: () => _accept(context, ref, invites[index]),
                onDecline: () => _decline(context, ref, invites[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    GroupDirectInvite invite,
  ) async {
    try {
      final result = await ref
          .read(groupActionControllerProvider.notifier)
          .acceptDirectInvite(invite.id);
      if (!context.mounted) return;
      final message = result.status == GroupInviteStatus.alreadyMember
          ? context.l10n.groupInviteAlreadyMember
          : context.l10n.groupInviteAccepted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.go(GroupDetailScreen.routePath, extra: result.groupId);
    } catch (_) {
      // The controller listener maps stable backend codes to localized text.
    }
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    GroupDirectInvite invite,
  ) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .declineDirectInvite(invite.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupInvitationDeclinedSuccess)),
      );
    } catch (_) {
      // The controller listener maps stable backend codes to localized text.
    }
  }
}

class _DirectInviteCard extends StatelessWidget {
  const _DirectInviteCard({
    required this.invite,
    required this.isLoading,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupDirectInvite invite;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SupabaseImage(
                  imagePath: invite.groupAvatarPath,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(16),
                  fallbackIcon: Icons.groups_2_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.groupName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.groupInvitationInvitedBy(
                          invite.inviterName,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: invite.status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.groupInvitationExpiresAt(
                _formatDate(invite.expiresAt),
              ),
              style: context.moniaryTypography.metadata.copyWith(
                color: colors.textDim,
              ),
            ),
            if (invite.canRespond) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : onDecline,
                      child: Text(context.l10n.groupInvitationDecline),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading ? null : onAccept,
                      child: Text(context.l10n.groupInvitationAccept),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final GroupDirectInviteStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final color = switch (status) {
      GroupDirectInviteStatus.pending => colors.warning,
      GroupDirectInviteStatus.accepted ||
      GroupDirectInviteStatus.alreadyMember => colors.success,
      GroupDirectInviteStatus.declined ||
      GroupDirectInviteStatus.expired ||
      GroupDirectInviteStatus.revoked ||
      GroupDirectInviteStatus.invalid => colors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(context),
        style: context.moniaryTypography.metadataStrong.copyWith(color: color),
      ),
    );
  }

  String _label(BuildContext context) => switch (status) {
    GroupDirectInviteStatus.pending => context.l10n.groupInvitationPending,
    GroupDirectInviteStatus.accepted => context.l10n.groupInvitationAccepted,
    GroupDirectInviteStatus.declined => context.l10n.groupInvitationDeclined,
    GroupDirectInviteStatus.expired => context.l10n.groupInvitationExpired,
    GroupDirectInviteStatus.revoked => context.l10n.groupInvitationRevoked,
    GroupDirectInviteStatus.alreadyMember =>
      context.l10n.groupInviteAlreadyMember,
    GroupDirectInviteStatus.invalid => context.l10n.groupInvitationInvalid,
  };
}

class _InviteMessageState extends StatelessWidget {
  const _InviteMessageState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: context.moniaryColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
