import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupPublicProfileScreen extends ConsumerStatefulWidget {
  const GroupPublicProfileScreen({required this.groupId, super.key})
    : slug = null,
      isPublicView = false;

  const GroupPublicProfileScreen.public({required this.slug, super.key})
    : groupId = null,
      isPublicView = true;

  static const routePath = '/group-public-profile';
  static const publicRoutePath = '/public-group/:slug';

  static String publicRouteLocation(String slug) =>
      '/public-group/${Uri.encodeComponent(slug)}';

  final String? groupId;
  final String? slug;
  final bool isPublicView;

  @override
  ConsumerState<GroupPublicProfileScreen> createState() =>
      _GroupPublicProfileScreenState();
}

class _GroupPublicProfileScreenState
    extends ConsumerState<GroupPublicProfileScreen> {
  final _slugController = TextEditingController();
  bool? _enabled;
  bool? _showStats;
  bool _initialized = false;

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = widget.isPublicView
        ? ref.watch(publicGroupProfileProvider(widget.slug!))
        : ref.watch(groupPublicProfileProvider(widget.groupId!));
    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(
        title: Text(
          widget.isPublicView
              ? context.l10n.groupPublicProfileTitle
              : context.l10n.groupPublicProfileSettingsTitle,
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: userFriendlyMessage(context, error),
          onRetry: () => widget.isPublicView
              ? ref.invalidate(publicGroupProfileProvider(widget.slug!))
              : ref.invalidate(groupPublicProfileProvider(widget.groupId!)),
        ),
        data: (profile) => widget.isPublicView
            ? _PublicView(profile: profile)
            : _SettingsView(
                profile: profile,
                slugController: _slugController,
                initialized: _initialized,
                onInitialize: () {
                  if (_initialized) return;
                  _initialized = true;
                  _slugController.text = profile.slug ?? '';
                  _enabled = profile.isEnabled;
                  _showStats = profile.showStats;
                },
                enabled: _enabled ?? profile.isEnabled,
                showStats: _showStats ?? profile.showStats,
                onEnabledChanged: (value) => setState(() => _enabled = value),
                onShowStatsChanged: (value) =>
                    setState(() => _showStats = value),
                onSave: () => _save(profile),
              ),
      ),
    );
  }

  Future<void> _save(GroupPublicProfile profile) async {
    final slug = _slugController.text.trim().toLowerCase();
    if (slug.isNotEmpty && !RegExp(r'^[a-z0-9-]{3,80}$').hasMatch(slug)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupPublicProfileInvalidSlug)),
      );
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updatePublicProfile(
            profile.copyWith(
              slug: slug.isEmpty ? null : slug,
              clearSlug: slug.isEmpty,
              isEnabled: _enabled,
              showStats: _showStats,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.commonSaved)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyMessage(context, error))),
        );
      }
    }
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.profile,
    required this.slugController,
    required this.initialized,
    required this.onInitialize,
    required this.enabled,
    required this.showStats,
    required this.onEnabledChanged,
    required this.onShowStatsChanged,
    required this.onSave,
  });

  final GroupPublicProfile profile;
  final TextEditingController slugController;
  final bool initialized;
  final VoidCallback onInitialize;
  final bool enabled;
  final bool showStats;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onShowStatsChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    onInitialize();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 36),
      children: [
        Text(context.l10n.groupPublicProfileSettingsSubtitle),
        const SizedBox(height: 18),
        TextField(
          controller: slugController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.l10n.groupPublicProfileSlug,
            prefixText: '/public-group/',
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.groupPublicProfileEnabled),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.groupPublicProfileShowStats),
          subtitle: Text(context.l10n.groupPublicProfileShowStatsSubtitle),
          value: showStats,
          onChanged: enabled ? onShowStatsChanged : null,
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: onSave, child: Text(context.l10n.commonSave)),
        if (enabled && profile.slug?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          Text(
            context.l10n.groupPublicProfileShareTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            'https://go.vuivethoima.id.vn${GroupPublicProfileScreen.publicRouteLocation(profile.slug!)}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'https://go.vuivethoima.id.vn${GroupPublicProfileScreen.publicRouteLocation(profile.slug!)}',
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.groupPublicProfileCopied),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(context.l10n.groupPublicProfileCopy),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  GroupPublicProfileScreen.publicRouteLocation(profile.slug!),
                ),
                icon: const Icon(Icons.open_in_new_outlined),
                label: Text(context.l10n.groupPublicProfilePreview),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PublicView extends StatelessWidget {
  const _PublicView({required this.profile});
  final GroupPublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 36),
      children: [
        Center(
          child: SupabaseImage(
            // Group avatars live in private storage and are only available to
            // active members. Public pages intentionally use a safe fallback
            // until a separate public asset path is provisioned.
            imagePath: null,
            width: 92,
            height: 92,
            borderRadius: BorderRadius.circular(46),
            fallbackIcon: Icons.groups_outlined,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.groupName ?? context.l10n.groupPublicProfileFallbackName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (profile.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(profile.description!, textAlign: TextAlign.center),
        ],
        if (profile.showStats) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    label: context.l10n.groupPublicProfileMembers,
                    value: '${profile.memberCount ?? 0}',
                  ),
                  _Stat(
                    label: context.l10n.groupPublicProfileTransactions,
                    value: '${profile.transactionCount ?? 0}',
                  ),
                  _Stat(
                    label: context.l10n.groupPublicProfileTotalSpent,
                    value: '${profile.totalSpent ?? 0}',
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        Text(
          context.l10n.groupPublicProfileSafeNotice,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}
