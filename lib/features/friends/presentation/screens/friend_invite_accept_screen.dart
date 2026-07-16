import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/friend_controller.dart';
import '../../domain/entities/friend_profile.dart';
import '../widgets/friend_profile_tile.dart';
import 'friends_screen.dart';

class FriendInviteAcceptScreen extends ConsumerWidget {
  const FriendInviteAcceptScreen({required this.token, super.key});

  static const routePath = '/friends/invite/:token';

  static String routeLocation(String token) {
    return '/friends/invite/${Uri.encodeComponent(token)}';
  }

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewAsync = ref.watch(friendInvitePreviewProvider(token));
    final action = ref.watch(friendActionControllerProvider);

    ref.listen(friendActionControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyMessage(context, error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.friendInviteAcceptTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: previewAsync.when(
            loading: () => _MessageState(
              icon: Icons.mark_email_unread_outlined,
              title: context.l10n.friendInviteLoading,
            ),
            error: (error, stackTrace) {
              AppLogger.error(
                'Failed to load friend invite preview',
                error,
                stackTrace,
              );
              return _MessageState(
                icon: Icons.link_off_outlined,
                title: context.l10n.friendInvitePreviewError,
                action: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(friendInvitePreviewProvider(token)),
                  child: Text(context.l10n.retry),
                ),
              );
            },
            data: (preview) => _InviteBody(
              preview: preview,
              actionLoading: action.isLoading,
              onAccept: () => _accept(context, ref),
              onDecline: () => _decline(context),
              onOpenFriends: () => context.go(FriendsScreen.routePath),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(friendActionControllerProvider.notifier)
          .acceptInvite(token);
      if (!context.mounted) return;
      final message = result.status == FriendInviteAcceptStatus.alreadyFriends
          ? context.l10n.friendInviteAlreadyFriends
          : context.l10n.friendInviteAccepted;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.go(FriendsScreen.routePath);
    } catch (_) {
      // The listener above maps AppException codes to localized SnackBars.
    }
  }

  void _decline(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(FriendsScreen.routePath);
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({
    required this.preview,
    required this.actionLoading,
    required this.onAccept,
    required this.onDecline,
    required this.onOpenFriends,
  });

  final FriendInvitePreview preview;
  final bool actionLoading;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context) {
    final inviter = preview.inviter;
    final statusMessage = _statusMessage(context, preview);
    if (!preview.canAccept) {
      return _MessageState(
        icon: _statusIcon(preview),
        title: statusMessage,
        action: FilledButton(
          onPressed: onOpenFriends,
          child: Text(context.l10n.friendInviteOpenFriends),
        ),
        child: inviter == null
            ? null
            : FriendProfileTile(
                profile: inviter,
                subtitle: inviter.displayUsername,
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > 560
            ? 560.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          color: context.moniaryColors.primary,
                          size: 64,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.friendInviteAcceptTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.friendInviteAcceptSubtitle(
                            inviter?.displayName ?? context.l10n.friendsTitle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (inviter != null) ...[
                          const SizedBox(height: 28),
                          FriendProfileTile(
                            profile: inviter,
                            subtitle: inviter.displayUsername,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: FilledButton.icon(
                          onPressed: actionLoading ? null : onAccept,
                          icon: actionLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add_alt_1_outlined),
                          label: Text(
                            context.l10n.friendInviteAcceptButton,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: OutlinedButton.icon(
                          onPressed: actionLoading ? null : onDecline,
                          icon: const Icon(Icons.person_remove_outlined),
                          label: Text(
                            context.l10n.friendDecline,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusMessage(BuildContext context, FriendInvitePreview preview) {
    // Friendship/self are derived from both the link status and the relation
    // status, so they take priority over the raw link status (e.g. a `used`
    // link between two people who are already friends).
    if (preview.isAlreadyFriends) {
      return context.l10n.friendInviteAlreadyFriends;
    }
    if (preview.isSelf) {
      return context.l10n.friendInviteSelf;
    }
    switch (preview.status) {
      case FriendInviteStatus.used:
        return context.l10n.friendInviteUsed;
      case FriendInviteStatus.revoked:
        return context.l10n.friendInviteRevoked;
      case FriendInviteStatus.expired:
        return context.l10n.friendInviteExpired;
      case FriendInviteStatus.invalid:
        return context.l10n.friendInviteInvalid;
      case FriendInviteStatus.active:
      case FriendInviteStatus.self:
      case FriendInviteStatus.alreadyFriends:
        return context.l10n.friendInviteAlreadyFriends;
    }
  }

  IconData _statusIcon(FriendInvitePreview preview) {
    if (preview.isAlreadyFriends) return Icons.people_alt_outlined;
    if (preview.isSelf) return Icons.person_off_outlined;
    return Icons.link_off_outlined;
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
