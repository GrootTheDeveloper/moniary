import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_navigation.dart';
import '../../../../app/app_theme.dart';
import '../../../../core/deeplinks/pending_deep_link_controller.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/friend_controller.dart';
import '../../domain/entities/friend_profile.dart';
import 'friend_profile_tile.dart';

class FriendInvitePromptHost extends ConsumerStatefulWidget {
  const FriendInvitePromptHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FriendInvitePromptHost> createState() =>
      _FriendInvitePromptHostState();
}

class _FriendInvitePromptHostState
    extends ConsumerState<FriendInvitePromptHost> {
  String? _activeToken;
  String? _scheduledToken;

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(pendingFriendInvitePromptProvider, (previous, token) {
      if (token != null) _scheduleInviteDialog(token);
    });

    final token = ref.watch(pendingFriendInvitePromptProvider);
    if (token != null) _scheduleInviteDialog(token);
    return widget.child;
  }

  void _scheduleInviteDialog(String token) {
    if (!mounted) return;
    if (token == _activeToken || token == _scheduledToken) return;
    _scheduledToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(pendingFriendInvitePromptProvider) != token) {
        if (_scheduledToken == token) _scheduledToken = null;
        return;
      }
      _showInviteDialog(token);
    });
  }

  Future<void> _showInviteDialog(String token) async {
    if (_activeToken != null && _activeToken != token) return;
    final navigator =
        appRootNavigatorKey.currentState ??
        Navigator.maybeOf(context, rootNavigator: true);
    final dialogContext = appRootNavigatorKey.currentContext ?? context;
    if (navigator == null) {
      _scheduledToken = null;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted && ref.read(pendingFriendInvitePromptProvider) == token) {
          _scheduleInviteDialog(token);
        }
      });
      return;
    }

    _activeToken = token;
    _scheduledToken = null;
    try {
      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => _FriendInvitePromptDialog(token: token),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to show friend invite prompt', error, stackTrace);
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted && ref.read(pendingFriendInvitePromptProvider) == token) {
          _scheduleInviteDialog(token);
        }
      });
    } finally {
      if (mounted) {
        if (ref.read(pendingFriendInvitePromptProvider) == token) {
          ref.read(pendingFriendInvitePromptProvider.notifier).clear();
        }
      }
      _activeToken = null;
    }
  }
}

class _FriendInvitePromptDialog extends ConsumerWidget {
  const _FriendInvitePromptDialog({required this.token});

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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: previewAsync.when(
          loading: () => _DialogMessage(
            icon: Icons.mark_email_unread_outlined,
            title: context.l10n.friendInviteLoading,
          ),
          error: (error, stackTrace) {
            AppLogger.error(
              'Failed to load friend invite prompt',
              error,
              stackTrace,
            );
            return _DialogMessage(
              icon: Icons.link_off_outlined,
              title: context.l10n.friendInvitePreviewError,
              actions: [
                TextButton(
                  onPressed: () {
                    ref
                        .read(pendingFriendInvitePromptProvider.notifier)
                        .clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(context.l10n.commonClose),
                ),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(friendInvitePreviewProvider(token)),
                  child: Text(context.l10n.retry),
                ),
              ],
            );
          },
          data: (preview) => _FriendInvitePromptBody(
            token: token,
            preview: preview,
            actionLoading: action.isLoading,
          ),
        ),
      ),
    );
  }
}

class _FriendInvitePromptBody extends ConsumerWidget {
  const _FriendInvitePromptBody({
    required this.token,
    required this.preview,
    required this.actionLoading,
  });

  final String token;
  final FriendInvitePreview preview;
  final bool actionLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviter = preview.inviter;
    if (!preview.canAccept) {
      return _DialogMessage(
        icon: Icons.link_off_outlined,
        title: _statusMessage(context, preview.status),
        actions: [
          FilledButton(
            onPressed: () {
              ref.read(pendingFriendInvitePromptProvider.notifier).clear();
              Navigator.of(context).pop();
            },
            child: Text(context.l10n.commonClose),
          ),
        ],
        child: inviter == null
            ? null
            : FriendProfileTile(
                profile: inviter,
                subtitle: inviter.displayUsername,
              ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.person_add_alt_1_outlined,
          color: AppTheme.mint,
          size: 52,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.friendInviteAcceptTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: context.moniaryColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.friendInviteAcceptSubtitle(
            inviter?.displayName ?? context.l10n.friendsTitle,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (inviter != null) ...[
          const SizedBox(height: 18),
          FriendProfileTile(
            profile: inviter,
            subtitle: inviter.displayUsername,
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: actionLoading
                    ? null
                    : () {
                        ref
                            .read(pendingFriendInvitePromptProvider.notifier)
                            .clear();
                        Navigator.of(context).pop();
                      },
                child: Text(context.l10n.friendDecline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: actionLoading ? null : () => _accept(context, ref),
                child: actionLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.friendInviteAgreeButton),
              ),
            ),
          ],
        ),
      ],
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
      final messenger = ScaffoldMessenger.of(context);
      ref.read(pendingFriendInvitePromptProvider.notifier).clear();
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      // The listener above maps AppException codes to localized SnackBars.
    }
  }

  String _statusMessage(BuildContext context, FriendInviteStatus status) {
    switch (status) {
      case FriendInviteStatus.active:
        return context.l10n.friendInviteAcceptTitle;
      case FriendInviteStatus.used:
        return context.l10n.friendInviteUsed;
      case FriendInviteStatus.revoked:
        return context.l10n.friendInviteRevoked;
      case FriendInviteStatus.expired:
        return context.l10n.friendInviteExpired;
      case FriendInviteStatus.invalid:
        return context.l10n.friendInviteInvalid;
      case FriendInviteStatus.self:
        return context.l10n.friendInviteSelf;
      case FriendInviteStatus.alreadyFriends:
        return context.l10n.friendInviteAlreadyFriends;
    }
  }
}

class _DialogMessage extends StatelessWidget {
  const _DialogMessage({
    required this.icon,
    required this.title,
    this.child,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final Widget? child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 52, color: AppTheme.mintSoft),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (child != null) ...[const SizedBox(height: 18), child!],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: action,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
