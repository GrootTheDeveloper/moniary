import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../domain/entities/group_transaction.dart';

class CommentList extends StatelessWidget {
  const CommentList({
    required this.comments,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<GroupTransactionComment> comments;
  final String currentUserId;
  final void Function(GroupTransactionComment comment) onEdit;
  final void Function(GroupTransactionComment comment) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: comments
          .map(
            (comment) => _CommentTile(
              comment: comment,
              isOwner: comment.userId == currentUserId,
              onEdit: () => onEdit(comment),
              onDelete: () => onDelete(comment),
            ),
          )
          .toList(),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final GroupTransactionComment comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.surfaceRaised,
        child: const Icon(Icons.person_outline),
      ),
      title: Text(comment.displayName ?? context.l10n.groupUnknownMember),
      subtitle: Text(comment.content),
      trailing: isOwner
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined),
                      const SizedBox(width: 10),
                      Text(context.l10n.commonEdit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline),
                      const SizedBox(width: 10),
                      Text(context.l10n.commonDelete),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }
}
