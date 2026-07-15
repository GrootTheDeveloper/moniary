import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/spending_group.dart';

class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({required this.groupId, super.key});

  static const routePath = '/group-settings';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupSettingsTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (detail) =>
            _GroupSettingsForm(groupId: groupId, group: detail.group),
      ),
    );
  }
}

class _GroupSettingsForm extends ConsumerStatefulWidget {
  const _GroupSettingsForm({required this.groupId, required this.group});

  final String groupId;
  final SpendingGroup group;

  @override
  ConsumerState<_GroupSettingsForm> createState() => _GroupSettingsFormState();
}

class _GroupSettingsFormState extends ConsumerState<_GroupSettingsForm> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _type;
  String? _avatarPath;
  late String _baseCurrency;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _description = TextEditingController(text: widget.group.description);
    _type = TextEditingController(text: widget.group.type);
    _baseCurrency = widget.group.baseCurrency;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final actionState = ref.watch(groupActionControllerProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Text(context.l10n.groupSettingsSubtitle),
        const SizedBox(height: 22),
        Center(
          child: Column(
            children: [
              InkWell(
                onTap: actionState.isLoading ? null : _pickAvatar,
                borderRadius: BorderRadius.circular(48),
                child: _avatarPath == null
                    ? SupabaseImage(
                        imagePath: widget.group.avatarPath,
                        width: 96,
                        height: 96,
                        borderRadius: BorderRadius.circular(48),
                        fallbackIcon: Icons.groups_outlined,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(48),
                        child: Image.file(
                          File(_avatarPath!),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              TextButton.icon(
                onPressed: actionState.isLoading ? null : _pickAvatar,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(context.l10n.groupChooseImage),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.groupSettingsName,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: context.l10n.groupSettingsDescription,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _type,
          decoration: InputDecoration(
            labelText: context.l10n.groupSettingsType,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _baseCurrency,
          decoration: InputDecoration(
            labelText: context.l10n.groupSettingsBaseCurrency,
            helperText: context.l10n.groupSettingsBaseCurrencySubtitle,
          ),
          items: const [
            DropdownMenuItem(value: 'VND', child: Text('VND')),
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            DropdownMenuItem(value: 'SGD', child: Text('SGD')),
            DropdownMenuItem(value: 'JPY', child: Text('JPY')),
          ],
          onChanged: (value) => setState(() => _baseCurrency = value ?? 'VND'),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: actionState.isLoading ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(context.l10n.groupSettingsSave),
        ),
        const SizedBox(height: 30),
        Card(
          color: colors.danger.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.groupSettingsArchiveTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(context.l10n.groupSettingsArchiveSubtitle),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: actionState.isLoading ? null : _archive,
                  icon: Icon(Icons.archive_outlined, color: colors.danger),
                  label: Text(context.l10n.groupSettingsArchiveAction),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateGroup(
            groupId: widget.groupId,
            name: _name.text,
            description: _description.text,
            type: _type.text,
          );
      if (_avatarPath != null) {
        await ref
            .read(groupActionControllerProvider.notifier)
            .updateGroupAvatar(groupId: widget.groupId, filePath: _avatarPath!);
      }
      await ref
          .read(groupActionControllerProvider.notifier)
          .updateGroupCurrency(
            groupId: widget.groupId,
            baseCurrency: _baseCurrency,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupSettingsSaved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image != null && mounted) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupSettingsArchiveConfirmTitle),
        content: Text(context.l10n.groupSettingsArchiveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.groupSettingsArchiveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .setGroupArchived(groupId: widget.groupId, archived: true);
      if (mounted) context.go('/groups');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
