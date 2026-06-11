import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';

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
              context.l10n.groupInviteLinkPlaceholder,
              style: Theme.of(context).textTheme.bodyMedium,
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
                Text(context.l10n.groupNoFriends),
              ],
            ),
          ),
        ],
      ),
    );
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
}
