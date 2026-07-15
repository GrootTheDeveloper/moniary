import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/friend_controller.dart';
import '../../domain/entities/friend_profile.dart';
import 'add_friend_screen.dart';
import 'friend_qr_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  static const routePath = '/friends';

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  late final TextEditingController _searchController;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsControllerProvider);
    final incomingAsync = ref.watch(incomingFriendRequestsProvider);
    final pendingIncomingCount = ref.watch(
      pendingIncomingFriendRequestCountProvider,
    );
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

    final colors = context.moniaryColors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.background,
        systemNavigationBarDividerColor: colors.outline,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            color: colors.button,
            backgroundColor: colors.surface,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _FriendsTopBar(
                  onBack: _canPop(context)
                      ? () => Navigator.of(context).maybePop()
                      : null,
                  onAdd: () => context.push(AddFriendScreen.routePath),
                  onQr: () => context.push(FriendQrScreen.routePath),
                  onRequests: () => _showFriendRequestsSheet(context),
                  pendingRequestCount: pendingIncomingCount,
                ),
                const SizedBox(height: 22),
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 22),
                incomingAsync.when(
                  loading: () => const SizedBox.shrink(),
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
                          onDecline: (request) =>
                              _decline(context, ref, request),
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
                    AppLogger.error(
                      'Failed to load friends',
                      error,
                      stackTrace,
                    );
                    return _SectionError(onRetry: () => _refresh(ref));
                  },
                  data: (friends) => _FriendsSection(
                    friends: _filteredFriends(friends),
                    totalCount: friends.length,
                    searchQuery: _query.trim(),
                    actionLoading: action.isLoading,
                    onAdd: () => context.push(AddFriendScreen.routePath),
                    onShare: () => _shareInviteLink(context, ref),
                    onRemove: (friend) => _showFriendActions(
                      context: context,
                      friend: friend,
                      onRemove: () => _confirmRemove(context, ref, friend),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FriendProfile> _filteredFriends(List<FriendProfile> friends) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return friends;
    return friends
        .where((friend) {
          return friend.displayName.toLowerCase().contains(query) ||
              friend.displayUsername.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  bool _canPop(BuildContext context) {
    return Navigator.of(context).canPop() ||
        (GoRouter.maybeOf(context)?.canPop() ?? false);
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(incomingFriendRequestsProvider);
    ref.invalidate(outgoingFriendRequestsProvider);
    await ref.read(friendsControllerProvider.notifier).refresh();
  }

  Future<void> _shareInviteLink(BuildContext context, WidgetRef ref) async {
    try {
      final invite = await ref
          .read(friendActionControllerProvider.notifier)
          .createInviteLink();
      if (!context.mounted) return;
      await Share.share(
        context.l10n.friendInviteShareMessage(invite.link),
        subject: context.l10n.friendShareInviteLink,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
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

  Future<void> _showFriendRequestsSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final incomingAsync = ref.watch(incomingFriendRequestsProvider);
          final action = ref.watch(friendActionControllerProvider);
          final colors = context.moniaryColors;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.friendIncomingRequests,
                      textAlign: TextAlign.center,
                      style: context.moniaryTypography.displaySmall.copyWith(
                        fontSize: 22,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: incomingAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stackTrace) {
                          AppLogger.error(
                            'Failed to load friend request inbox',
                            error,
                            stackTrace,
                          );
                          return _SectionError(onRetry: () => _refresh(ref));
                        },
                        data: (requests) {
                          if (requests.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 36,
                                ),
                                child: Text(
                                  context.l10n.friendRequestsEmpty,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.textDim),
                                ),
                              ),
                            );
                          }
                          return ListView(
                            shrinkWrap: true,
                            children: [
                              _RequestSection(
                                title: context.l10n.friendIncomingRequests,
                                requests: requests,
                                actionLoading: action.isLoading,
                                onAccept: (request) =>
                                    _accept(sheetContext, ref, request),
                                onDecline: (request) =>
                                    _decline(sheetContext, ref, request),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  Future<void> _showFriendActions({
    required BuildContext context,
    required FriendProfile friend,
    required VoidCallback onRemove,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.moniaryColors.surface,
      showDragHandle: true,
      builder: (context) {
        final colors = context.moniaryColors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  friend.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRemove();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(
                      color: colors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  icon: const Icon(Icons.person_remove_alt_1_outlined),
                  label: Text(context.l10n.friendRemove),
                ),
              ],
            ),
          ),
        );
      },
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

class _FriendsTopBar extends StatelessWidget {
  const _FriendsTopBar({
    required this.onAdd,
    required this.onQr,
    required this.onRequests,
    required this.pendingRequestCount,
    this.onBack,
  });

  final VoidCallback? onBack;
  final VoidCallback onAdd;
  final VoidCallback onQr;
  final VoidCallback onRequests;
  final int pendingRequestCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _IconSquareButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
              icon: Icons.arrow_back_ios_new_rounded,
            ),
          ),
          _TitleWithBadge(
            title: context.l10n.friendsTitle,
            badge: pendingRequestCount,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconSquareButton(
                  tooltip: context.l10n.friendQrTitle,
                  onPressed: onQr,
                  icon: Icons.qr_code_scanner_outlined,
                ),
                const SizedBox(width: 8),
                _IconSquareButton(
                  tooltip: context.l10n.friendIncomingRequests,
                  onPressed: onRequests,
                  icon: pendingRequestCount > 0
                      ? Icons.mark_email_unread_outlined
                      : Icons.mark_email_read_outlined,
                  badge: pendingRequestCount,
                ),
                const SizedBox(width: 8),
                _IconSquareButton(
                  tooltip: context.l10n.friendAdd,
                  onPressed: onAdd,
                  icon: Icons.person_add_alt_1_rounded,
                  filled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleWithBadge extends StatelessWidget {
  const _TitleWithBadge({required this.title, required this.badge});

  final String title;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: context.moniaryTypography.displaySmall.copyWith(
            fontSize: 22,
            color: colors.textPrimary,
          ),
        ),
        if (badge > 0) ...[
          const SizedBox(width: 8),
          _FriendRequestBadge(count: badge),
        ],
      ],
    );
  }
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.filled = false,
    this.badge = 0,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool filled;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final background = filled ? colors.button : colors.surface;
    final foreground = filled ? colors.surface : colors.icon;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: filled ? null : Border.all(color: colors.outline),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 21, color: foreground),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: _FriendRequestBadge(count: badge),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRequestBadge extends StatelessWidget {
  const _FriendRequestBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.moniaryColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: AppTheme.surfaceRaised,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.friendSearchPlaceholder,
        prefixIcon: Icon(Icons.search_rounded, color: colors.textDim, size: 22),
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colors.button, width: 1.2),
        ),
      ),
    );
  }
}

class _FriendsSection extends StatelessWidget {
  const _FriendsSection({
    required this.friends,
    required this.totalCount,
    required this.searchQuery,
    required this.actionLoading,
    required this.onAdd,
    required this.onShare,
    required this.onRemove,
  });

  final List<FriendProfile> friends;
  final int totalCount;
  final String searchQuery;
  final bool actionLoading;
  final VoidCallback onAdd;
  final VoidCallback onShare;
  final ValueChanged<FriendProfile> onRemove;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return _EmptyFriendsState(
        onAdd: onAdd,
        onShare: actionLoading ? null : onShare,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(context.l10n.friendListSection(totalCount)),
        const SizedBox(height: 5),
        if (friends.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 34),
            child: Text(
              context.l10n.friendSearchEmpty(searchQuery),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          for (var index = 0; index < friends.length; index++)
            _FriendRow(
              friend: friends[index],
              showDivider: index != friends.length - 1,
              onTap: actionLoading ? null : () => onRemove(friends[index]),
            ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.showDivider,
    required this.onTap,
  });

  final FriendProfile friend;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              decoration: BoxDecoration(
                border: showDivider
                    ? Border(
                        bottom: BorderSide(
                          color: colors.outline.withValues(alpha: 0.55),
                        ),
                      )
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  ClipOval(
                    child: SupabaseImage(
                      imagePath: friend.avatarPath,
                      width: 48,
                      height: 48,
                      fallbackIcon: Icons.person_outline_rounded,
                      fallbackBuilder: (context) =>
                          _AvatarFallback(friend: friend),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n
                              .friendSharedGroups(friend.sharedGroupCount)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.textDim,
                          ),
                        ),
                        if (compact) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _FriendBalance(profile: friend),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    _FriendBalance(profile: friend),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final letter = friend.displayName.trim().isEmpty
        ? '?'
        : friend.displayName.trim().characters.first.toUpperCase();
    return Container(
      width: 48,
      height: 48,
      color: colors.secondary.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FriendBalance extends ConsumerWidget {
  const _FriendBalance({required this.profile});

  final FriendProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final balance = profile.currentUserBalance;
    final isSettled = balance == 0;
    final color = balance > 0
        ? colors.success
        : balance < 0
        ? colors.danger
        : colors.textDim;
    final label = balance > 0
        ? context.l10n.friendOwesYou
        : balance < 0
        ? context.l10n.friendYouOwe
        : context.l10n.friendBalanceSettled;
    final amount = isSettled
        ? ref.formatAmount(0)
        : '${balance > 0 ? '+' : '-'}${ref.formatAmount(balance.abs())}';

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 82, maxWidth: 108),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.metadataStrong.copyWith(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.moniaryTypography.metadata.copyWith(
              color: colors.textDim,
            ),
          ),
        ],
      ),
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
    return _CompactSection(
      title: title,
      children: [
        for (final request in requests)
          _RequestRow(
            request: request,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RequestIconButton(
                  tooltip: context.l10n.friendDecline,
                  onPressed: actionLoading ? null : () => onDecline(request),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 6),
                _RequestIconButton(
                  tooltip: context.l10n.friendAccept,
                  onPressed: actionLoading ? null : () => onAccept(request),
                  icon: const Icon(Icons.check_rounded),
                  filled: true,
                ),
              ],
            ),
          ),
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
    return _CompactSection(
      title: context.l10n.friendOutgoingRequests,
      children: [
        for (final request in requests)
          _RequestRow(
            request: request,
            subtitle: context.l10n.friendRequestPending,
            trailing: TextButton(
              onPressed: actionLoading ? null : () => onCancel(request),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.l10n.friendCancel),
            ),
          ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.trailing,
    this.subtitle,
  });

  final FriendRequest request;
  final Widget trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final friend = request.otherProfile;
    final colors = context.moniaryColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the threshold with text size so large fonts fall back to the
        // stacked layout instead of overflowing the horizontal row.
        final compact =
            constraints.maxWidth < MediaQuery.textScalerOf(context).scale(300);
        final identity = Row(
          children: [
            ClipOval(
              child: SupabaseImage(
                imagePath: friend.avatarPath,
                width: 42,
                height: 42,
                fallbackBuilder: (context) => _AvatarFallback(friend: friend),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle ?? friend.displayUsername,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.moniaryTypography.metadata.copyWith(
                      color: colors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: trailing,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _RequestIconButton extends StatelessWidget {
  const _RequestIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.filled = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = filled
        ? IconButton.filled(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: icon,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        : IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: icon,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );

    return button;
  }
}

class _CompactSection extends StatelessWidget {
  const _CompactSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title, uppercase: false),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.uppercase = true});

  final String text;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? text.toUpperCase() : text,
      style: context.moniaryTypography.metadataStrong.copyWith(
        color: context.moniaryColors.textDim,
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  const _EmptyFriendsState({required this.onAdd, required this.onShare});

  final VoidCallback onAdd;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, size: 56, color: colors.textDim),
          const SizedBox(height: 16),
          Text(
            context.l10n.friendNoFriends,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.friendNoFriendsSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          // Wrap (not Row) so the buttons flow onto a second line instead of
          // overflowing — a fixed-width Row here crashes with unbounded-width
          // constraints at large text scales.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(context.l10n.friendAdd),
              ),
              IconButton.outlined(
                tooltip: context.l10n.friendShareInviteLink,
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 20),
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
