import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../application/friend_controller.dart';
import '../../domain/entities/friend_profile.dart';
import '../widgets/friend_profile_tile.dart';
import 'friend_qr_screen.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  static const routePath = '/friends/add';

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _usernameController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(friendActionControllerProvider);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final searchAsync = _query.isEmpty
        ? null
        : ref.watch(friendSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.friendAdd)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
        children: [
          MoniaryEditorialCard(
            radius: 22,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.friendSearchUsername.toUpperCase(),
                  style: context.moniaryTypography.metadataStrong,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: context.l10n.friendSearchHint,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '@',
                        style: context.moniaryTypography.displaySmall.copyWith(
                          color: context.moniaryColors.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: action.isLoading ? null : _search,
                  icon: const Icon(Icons.person_add_outlined),
                  label: Text(context.l10n.friendSearch),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Row(
              children: [
                Expanded(child: Divider(color: context.moniaryColors.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    context.l10n.friendInviteOr.toUpperCase(),
                    style: context.moniaryTypography.metadata,
                  ),
                ),
                Expanded(child: Divider(color: context.moniaryColors.outline)),
              ],
            ),
          ),
          _ShareInviteCard(
            isLoading: action.isLoading,
            onShare: _shareInviteLink,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(FriendQrScreen.routePath),
            icon: const Icon(Icons.qr_code_scanner_outlined),
            label: Text(context.l10n.friendQrTitle),
          ),
          const SizedBox(height: 18),
          if (searchAsync == null)
            _SearchHint()
          else
            searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                AppLogger.error('Failed to search friends', error, stackTrace);
                return _SearchError(onRetry: _search);
              },
              data: (results) {
                if (results.isEmpty) {
                  return _SearchEmpty(query: _query);
                }
                return Column(
                  children: [
                    for (final result in results) ...[
                      FriendProfileTile(
                        profile: result.profile,
                        subtitle: _relationLabel(context, result),
                        trailing: _SearchResultAction(
                          result: result,
                          isLoading: action.isLoading,
                          incomingRequest: _incomingRequestFor(
                            incomingAsync,
                            result.profile.userId,
                          ),
                          incomingRequestsLoading: incomingAsync.isLoading,
                          onSend: () => _sendRequest(result),
                          onAccept: _acceptIncomingRequest,
                          onDecline: _declineIncomingRequest,
                        ),
                      ),
                      if (result != results.last) const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _search() {
    final value = _usernameController.text.trim().toLowerCase();
    if (value.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.friendSearchPrompt)));
      return;
    }
    setState(() => _query = value);
  }

  Future<void> _shareInviteLink() async {
    try {
      final invite = await ref
          .read(friendActionControllerProvider.notifier)
          .createInviteLink();
      if (!mounted) return;
      await Share.share(
        context.l10n.friendInviteShareMessage(invite.link),
        subject: context.l10n.friendShareInviteLink,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  FriendRequest? _incomingRequestFor(
    AsyncValue<List<FriendRequest>> incomingAsync,
    String userId,
  ) {
    final requests = incomingAsync.asData?.value;
    if (requests == null) return null;
    for (final request in requests) {
      if (request.otherUserId == userId) {
        return request;
      }
    }
    return null;
  }

  Future<void> _sendRequest(FriendSearchResult result) async {
    try {
      await ref
          .read(friendActionControllerProvider.notifier)
          .sendRequestToUser(result.profile.userId);
      ref.invalidate(friendSearchProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.friendRequestSent)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _acceptIncomingRequest(FriendRequest request) async {
    try {
      await ref
          .read(friendActionControllerProvider.notifier)
          .acceptRequest(request.id);
      ref.invalidate(friendSearchProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.friendRequestAccepted)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _declineIncomingRequest(FriendRequest request) async {
    try {
      await ref
          .read(friendActionControllerProvider.notifier)
          .declineRequest(request.id);
      ref.invalidate(friendSearchProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.friendRequestDeclined)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  String _relationLabel(BuildContext context, FriendSearchResult result) {
    switch (result.relationStatus) {
      case FriendRelationStatus.friends:
        return context.l10n.friendAlreadyFriends;
      case FriendRelationStatus.outgoingPending:
        return context.l10n.friendRequestPending;
      case FriendRelationStatus.incomingPending:
        return context.l10n.friendIncomingPending;
      case FriendRelationStatus.self:
        return context.l10n.friendCannotAddSelf;
      case FriendRelationStatus.none:
        return result.profile.displayUsername;
    }
  }
}

class _ShareInviteCard extends StatelessWidget {
  const _ShareInviteCard({required this.isLoading, required this.onShare});

  final bool isLoading;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return MoniaryEditorialCard(
      onTap: isLoading ? null : onShare,
      radius: 18,
      backgroundColor: context.moniaryColors.primary.withValues(alpha: 0.08),
      borderColor: context.moniaryColors.primary.withValues(alpha: 0.26),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.moniaryColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.ios_share_outlined,
              color: context.moniaryColors.surface,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.friendShareInviteLink,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.friendInviteShareDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.arrow_forward, color: context.moniaryColors.primary),
        ],
      ),
    );
  }
}

class _SearchResultAction extends StatelessWidget {
  const _SearchResultAction({
    required this.result,
    required this.isLoading,
    required this.incomingRequest,
    required this.incomingRequestsLoading,
    required this.onSend,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendSearchResult result;
  final bool isLoading;
  final FriendRequest? incomingRequest;
  final bool incomingRequestsLoading;
  final VoidCallback onSend;
  final ValueChanged<FriendRequest> onAccept;
  final ValueChanged<FriendRequest> onDecline;

  @override
  Widget build(BuildContext context) {
    switch (result.relationStatus) {
      case FriendRelationStatus.none:
        return FilledButton(
          onPressed: isLoading ? null : onSend,
          child: Text(context.l10n.friendSendRequest),
        );
      case FriendRelationStatus.incomingPending:
        final request = incomingRequest;
        if (incomingRequestsLoading && request == null) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (request == null) {
          return const Icon(
            Icons.check_circle_outline,
            color: AppTheme.success,
          );
        }
        return Wrap(
          spacing: 8,
          children: [
            IconButton.filledTonal(
              tooltip: context.l10n.friendDecline,
              onPressed: isLoading ? null : () => onDecline(request),
              icon: const Icon(Icons.close_outlined),
            ),
            IconButton.filled(
              tooltip: context.l10n.friendAccept,
              onPressed: isLoading ? null : () => onAccept(request),
              icon: const Icon(Icons.check_outlined),
            ),
          ],
        );
      case FriendRelationStatus.friends:
      case FriendRelationStatus.outgoingPending:
      case FriendRelationStatus.self:
        return const Icon(Icons.check_circle_outline, color: AppTheme.success);
    }
  }
}

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 48,
            color: context.moniaryColors.textDim,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.friendSearchPrompt, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 48,
            color: context.moniaryColors.textDim,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.friendSearchEmpty(query),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const _SearchError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Text(context.l10n.friendSearchError),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
