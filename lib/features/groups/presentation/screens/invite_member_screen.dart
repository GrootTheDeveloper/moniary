import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/app_theme.dart';
import '../../../friends/application/friend_controller.dart';
import '../../../friends/domain/entities/friend_profile.dart';
import '../../../friends/presentation/widgets/friend_profile_tile.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/spending_group.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({required this.groupId, super.key});

  static const routePath = '/groups/invite';

  final String groupId;

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _usernameController = TextEditingController();
  String? _inviteLink;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(groupActionControllerProvider);
    final friendsAsync = ref.watch(friendsControllerProvider);
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupInviteTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text(
            context.l10n.groupInviteByUsername,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: context.l10n.groupUsernameLabel,
              prefixIcon: const Icon(Icons.alternate_email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: action.isLoading ? null : _inviteUsername,
            child: Text(context.l10n.groupInviteAction),
          ),
          const SizedBox(height: 28),
          Text(
            context.l10n.groupInviteLinkTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: action.isLoading ? null : _createLink,
            icon: const Icon(Icons.link_outlined),
            label: Text(context.l10n.groupCreateInviteLink),
          ),
          if (_inviteLink != null) ...[
            const SizedBox(height: 12),
            SelectableText(_inviteLink!),
            const SizedBox(height: 6),
            Text(
              context.l10n.groupInviteLinkActiveNote,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: action.isLoading ? null : _copyLink,
                  icon: const Icon(Icons.content_copy_outlined),
                  label: Text(context.l10n.groupInviteCopyLink),
                ),
                OutlinedButton.icon(
                  onPressed: action.isLoading ? null : _shareLink,
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(context.l10n.groupShareInviteLink),
                ),
                TextButton.icon(
                  onPressed: action.isLoading ? null : _revokeLink,
                  icon: const Icon(Icons.link_off_outlined),
                  label: Text(context.l10n.groupInviteRevokeLink),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.groupFriendInviteTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                friendsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => Text(context.l10n.friendLoadError),
                  data: (friends) {
                    if (friends.isEmpty) {
                      return Text(context.l10n.groupNoFriends);
                    }
                    final members = detailAsync.asData?.value.members;
                    return Column(
                      children: [
                        for (final friend in friends) ...[
                          Builder(
                            builder: (context) {
                              final member = _memberForFriend(
                                members,
                                friend.userId,
                              );
                              final alreadyInGroup =
                                  member?.status == GroupMemberStatus.active ||
                                  member?.status == GroupMemberStatus.invited;
                              return FriendProfileTile(
                                profile: friend,
                                trailing: alreadyInGroup
                                    ? _MemberStatusChip(member: member!)
                                    : FilledButton(
                                        onPressed: action.isLoading
                                            ? null
                                            : () => _inviteFriend(friend),
                                        child: Text(
                                          context.l10n.groupInviteAction,
                                        ),
                                      ),
                              );
                            },
                          ),
                          if (friend != friends.last)
                            const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SpendingGroupMember? _memberForFriend(
    List<SpendingGroupMember>? members,
    String userId,
  ) {
    if (members == null) return null;
    for (final member in members) {
      if (member.userId == userId) {
        return member;
      }
    }
    return null;
  }

  Future<void> _inviteFriend(FriendProfile friend) async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .inviteByUserId(groupId: widget.groupId, userId: friend.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupInviteSent)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _inviteUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .inviteByUsername(groupId: widget.groupId, username: username);
      if (!mounted) return;
      _usernameController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupInviteSent)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _createLink() async {
    try {
      final link = await ref
          .read(groupActionControllerProvider.notifier)
          .createInviteLink(widget.groupId);
      if (!mounted) return;
      setState(() => _inviteLink = link);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupInviteLinkCreated)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _copyLink() async {
    final link = _inviteLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.groupInviteLinkCopied)));
  }

  Future<void> _revokeLink() async {
    final link = _inviteLink;
    if (link == null) return;
    final token = Uri.tryParse(link)?.pathSegments.last;
    if (token == null || token.isEmpty) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .revokeInviteLink(token);
      if (!mounted) return;
      setState(() => _inviteLink = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupInviteLinkRevoked)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _shareLink() async {
    final link = _inviteLink;
    if (link == null) return;
    await Share.share(context.l10n.groupInviteShareMessage(link));
  }
}

class _MemberStatusChip extends StatelessWidget {
  const _MemberStatusChip({required this.member});

  final SpendingGroupMember member;

  @override
  Widget build(BuildContext context) {
    final label = member.status == GroupMemberStatus.active
        ? context.l10n.groupMemberActive
        : context.l10n.groupMemberInvited;
    return Chip(label: Text(label));
  }
}
