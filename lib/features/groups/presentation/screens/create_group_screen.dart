import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';

class CreateGroupResult {
  const CreateGroupResult({required this.groupId, required this.inviteMembers});

  final String groupId;
  final bool inviteMembers;
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  static const routePath = '/groups/create';

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  String? _avatarPath;
  var _inviteMembers = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(groupActionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupCreateNew)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Center(
            child: InkWell(
              onTap: _pickAvatar,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 128,
                height: 128,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: _avatarPath == null
                    ? const Icon(Icons.add_photo_alternate_outlined, size: 42)
                    : Image.file(File(_avatarPath!), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _pickAvatar,
            child: Text(context.l10n.groupChooseImage),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.groupNameLabel,
              prefixIcon: const Icon(Icons.groups_2_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeController,
            decoration: InputDecoration(
              labelText: context.l10n.groupTypeLabel,
              hintText: context.l10n.groupTypeHint,
              prefixIcon: const Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: context.l10n.groupDescriptionLabel,
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _inviteMembers,
            onChanged: (value) => setState(() => _inviteMembers = value),
            title: Text(context.l10n.groupInviteAfterCreate),
            secondary: const Icon(Icons.person_add_outlined),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: action.isLoading ? null : _create,
            child: Text(
              action.isLoading
                  ? context.l10n.commonSaving
                  : context.l10n.groupCreateNew,
            ),
          ),
        ],
      ),
    );
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

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.groupNameRequired)));
      return;
    }
    try {
      final groupId = await ref
          .read(groupActionControllerProvider.notifier)
          .createGroup(
            name: _nameController.text,
            description: _descriptionController.text,
            type: _typeController.text,
            avatarFilePath: _avatarPath,
          );
      if (!mounted) return;
      context.pop(
        CreateGroupResult(groupId: groupId, inviteMembers: _inviteMembers),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
