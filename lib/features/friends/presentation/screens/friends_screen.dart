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
import 'add_friend_screen.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static const routePath = '/friends';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsControllerProvider);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final outgoingAsync = ref.watch(outgoingFriendRequestsProvider);
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
      appBar: AppBar(
        title: Text(context.l10n.friendsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.friendAdd,
            onPressed: () => context.push(AddFriendScreen.routePath),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            incomingAsync.when(
              loading: () => const _SectionLoading(),
              error: (error, stackTrace) {
                AppLogger.error(
                  'Failed to load incoming friend requests',
                  error,
                  stackTrace,
                );
                return _SectionError(onRetry: () => _refresh(ref));
              },
              data: (requests) => requests.isEmpty
                  ? const SizedBox.shrink()
                  : _RequestSection(
                      title: context.l10n.friendIncomingRequests,
                      requests: requests,
                      actionLoading: action.isLoading,
                      onAccept: (request) => _accept(context, ref, request),
                      onDecline: (request) => _decline(context, ref, request),
                    ),
            ),
            outgoingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) {
                AppLogger.error(
                  'Failed to load outgoing friend requests',
                  error,
                  stackTrace,
                );
                return _SectionError(onRetry: () => _refresh(ref));
              },
              data: (requests) => requests.isEmpty
                  ? const SizedBox.shrink()
                  : _OutgoingRequestSection(
                      requests: requests,
                      actionLoading: action.isLoading,
                      onCancel: (request) => _cancel(context, ref, request),
                    ),
            ),
            friendsAsync.when(
              loading: () => const _SectionLoading(),
              error: (error, stackTrace) {
                AppLogger.error('Failed to load friends', error, stackTrace);
                return _SectionError(onRetry: () => _refresh(ref));
              },
              data: (friends) => _FriendsSection(
                friends: friends,
                actionLoading: action.isLoading,
                onRemove: (friend) => _confirmRemove(context, ref, friend),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(outgoingFriendRequestsProvider);
    await ref.read(friendsControllerProvider.notifier).refresh();
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) async {
    await ref
        .read(friendActionControllerProvider.notifier)
        .acceptRequest(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendRequestAccepted)));
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) async {
    await ref
        .read(friendActionControllerProvider.notifier)
        .declineRequest(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendRequestDeclined)));
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    FriendRequest request,
  ) async {
    await ref
        .read(friendActionControllerProvider.notifier)
        .cancelRequest(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.friendRequestCancelled)),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    FriendProfile friend,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(context.l10n.friendRemoveTitle),
        content: Text(context.l10n.friendRemoveMessage(friend.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.friendRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(friendActionControllerProvider.notifier)
        .removeFriend(friend.userId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.friendRemoved)));
  }
}

class _FriendsSection extends StatelessWidget {
  const _FriendsSection({
    required this.friends,
    required this.actionLoading,
    required this.onRemove,
  });

  final List<FriendProfile> friends;
  final bool actionLoading;
  final ValueChanged<FriendProfile> onRemove;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return _EmptyFriendsState(
        onAdd: () => context.push(AddFriendScreen.routePath),
      );
    }
    return _SectionCard(
      title: context.l10n.friendsTitle,
      children: [
        for (final friend in friends) ...[
          FriendProfileTile(
            profile: friend,
            trailing: IconButton(
              tooltip: context.l10n.friendRemove,
              onPressed: actionLoading ? null : () => onRemove(friend),
              icon: const Icon(Icons.person_remove_alt_1_outlined),
            ),
          ),
          if (friend != friends.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RequestSection extends StatelessWidget {
  const _RequestSection({
    required this.title,
    required this.requests,
    required this.actionLoading,
    required this.onAccept,
    required this.onDecline,
  });

  final String title;
  final List<FriendRequest> requests;
  final bool actionLoading;
  final ValueChanged<FriendRequest> onAccept;
  final ValueChanged<FriendRequest> onDecline;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      children: [
        for (final request in requests) ...[
          FriendProfileTile(
            profile: request.otherProfile,
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton.filledTonal(
                  tooltip: context.l10n.friendDecline,
                  onPressed: actionLoading ? null : () => onDecline(request),
                  icon: const Icon(Icons.close_outlined),
                ),
                IconButton.filled(
                  tooltip: context.l10n.friendAccept,
                  onPressed: actionLoading ? null : () => onAccept(request),
                  icon: const Icon(Icons.check_outlined),
                ),
              ],
            ),
          ),
          if (request != requests.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _OutgoingRequestSection extends StatelessWidget {
  const _OutgoingRequestSection({
    required this.requests,
    required this.actionLoading,
    required this.onCancel,
  });

  final List<FriendRequest> requests;
  final bool actionLoading;
  final ValueChanged<FriendRequest> onCancel;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.friendOutgoingRequests,
      children: [
        for (final request in requests) ...[
          FriendProfileTile(
            profile: request.otherProfile,
            subtitle: context.l10n.friendRequestPending,
            trailing: TextButton(
              onPressed: actionLoading ? null : () => onCancel(request),
              child: Text(context.l10n.friendCancel),
            ),
          ),
          if (request != requests.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 72,
              color: AppTheme.mintSoft,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.friendNoFriends,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.friendNoFriendsSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(context.l10n.friendAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Text(context.l10n.friendLoadError),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
