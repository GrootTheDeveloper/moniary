import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupNotificationPreferencesScreen extends ConsumerStatefulWidget {
  const GroupNotificationPreferencesScreen({required this.groupId, super.key});

  static const routePath = '/group-notification-preferences';
  final String groupId;

  @override
  ConsumerState<GroupNotificationPreferencesScreen> createState() =>
      _GroupNotificationPreferencesScreenState();
}

class _GroupNotificationPreferencesScreenState
    extends ConsumerState<GroupNotificationPreferencesScreen> {
  GroupNotificationPreference? _draft;

  @override
  Widget build(BuildContext context) {
    final preferenceAsync = ref.watch(
      groupNotificationPreferenceProvider(widget.groupId),
    );
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(
        title: Text(context.l10n.groupNotificationPreferencesTitle),
      ),
      body: preferenceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userFriendlyMessage(context, error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  groupNotificationPreferenceProvider(widget.groupId),
                ),
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
        data: (preference) {
          _draft ??= preference;
          final value = _draft!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(context.l10n.groupNotificationPreferencesSubtitle),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _toggle(
                      context.l10n.groupNotificationMuteAll,
                      value.muteAll,
                      (next) => _update(value.copyWith(muteAll: next)),
                    ),
                    _toggle(
                      context.l10n.groupNotificationTransactions,
                      value.transactionNotifications,
                      (next) => _update(
                        value.copyWith(transactionNotifications: next),
                      ),
                      enabled: !value.muteAll,
                    ),
                    _toggle(
                      context.l10n.groupNotificationDebts,
                      value.debtNotifications,
                      (next) =>
                          _update(value.copyWith(debtNotifications: next)),
                      enabled: !value.muteAll,
                    ),
                    _toggle(
                      context.l10n.groupNotificationInvites,
                      value.inviteNotifications,
                      (next) =>
                          _update(value.copyWith(inviteNotifications: next)),
                      enabled: !value.muteAll,
                    ),
                    _toggle(
                      context.l10n.groupNotificationMentions,
                      value.mentionNotifications,
                      (next) =>
                          _update(value.copyWith(mentionNotifications: next)),
                      enabled: !value.muteAll,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.groupNotificationCommunitySection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Card(
                child: Column(
                  children: [
                    _toggle(
                      context.l10n.groupNotificationComments,
                      value.communityComments,
                      (next) =>
                          _update(value.copyWith(communityComments: next)),
                      enabled: !value.muteAll,
                    ),
                    _toggle(
                      context.l10n.groupNotificationReactions,
                      value.communityReactions,
                      (next) =>
                          _update(value.copyWith(communityReactions: next)),
                      enabled: !value.muteAll,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: ref.watch(groupActionControllerProvider).isLoading
                    ? null
                    : _save,
                child: Text(context.l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  void _update(GroupNotificationPreference value) =>
      setState(() => _draft = value);

  Future<void> _save() async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .saveNotificationPreference(_draft!);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.commonSaved)));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
    }
  }
}
