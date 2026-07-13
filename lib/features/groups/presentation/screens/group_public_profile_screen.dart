import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_roadmap.dart';

class GroupPublicProfileScreen extends ConsumerWidget {
  const GroupPublicProfileScreen({required this.groupId, super.key});

  static const routePath = '/groups/public-profile';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(groupPublicProfileProvider(groupId));
    final detailAsync = ref.watch(groupDetailProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupPublicProfileTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              userFriendlyMessage(context, error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (detail) => profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                userFriendlyMessage(context, error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (profile) => _ProfileForm(
            groupId: groupId,
            initial: profile,
            canEdit: detail.currentUserRole.index <= 1, // owner or admin
          ),
        ),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({
    required this.groupId,
    required this.initial,
    required this.canEdit,
  });

  final String groupId;
  final GroupPublicProfile initial;
  final bool canEdit;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  static final _slugPattern = RegExp(r'^[a-z0-9-]{3,80}$');

  late final TextEditingController _slugController;
  late bool _isEnabled;
  late bool _showStats;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController(text: widget.initial.slug ?? '');
    _isEnabled = widget.initial.isEnabled;
    _showStats = widget.initial.showStats;
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final canEdit = widget.canEdit;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: [
              // Public sharing is not live yet — no anonymous read path
              // exists in the backend, so these flags only store intent.
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceRaised.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: colors.textDim),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.groupPublicProfileComingSoon,
                        style: TextStyle(color: colors.textDim, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                value: _isEnabled,
                onChanged: canEdit
                    ? (value) => setState(() => _isEnabled = value)
                    : null,
                title: Text(context.l10n.groupPublicProfileEnable),
                subtitle: Text(context.l10n.groupPublicProfileEnableHelp),
                secondary: const Icon(Icons.public_outlined),
              ),
              SwitchListTile(
                value: _showStats,
                onChanged: canEdit && _isEnabled
                    ? (value) => setState(() => _showStats = value)
                    : null,
                title: Text(context.l10n.groupPublicProfileShowStats),
                subtitle: Text(context.l10n.groupPublicProfileShowStatsHelp),
                secondary: const Icon(Icons.bar_chart_outlined),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _slugController,
                  enabled: canEdit && _isEnabled,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                  ],
                  decoration: InputDecoration(
                    labelText: context.l10n.groupPublicProfileSlug,
                    hintText: context.l10n.groupPublicProfileSlugHint,
                    prefixIcon: const Icon(Icons.link_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (canEdit)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    _isSubmitting
                        ? context.l10n.commonSaving
                        : context.l10n.commonSave,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final rawSlug = _slugController.text.trim();
    final slug = rawSlug.isEmpty ? null : rawSlug;

    if (slug != null && !_slugPattern.hasMatch(slug)) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupPublicProfileSlugInvalid)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final profile = GroupPublicProfile(
      groupId: widget.groupId,
      isEnabled: _isEnabled,
      showStats: _isEnabled && _showStats,
      slug: slug,
    );

    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .upsertPublicProfile(profile);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.groupPublicProfileSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
