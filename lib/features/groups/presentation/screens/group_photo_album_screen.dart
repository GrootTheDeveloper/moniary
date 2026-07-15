import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_community_feed.dart';
import 'group_route_paths.dart';

final groupPhotoAlbumProvider =
    FutureProvider.family<List<GroupAlbumPhoto>, String>((ref, groupId) async {
      final transactions = await ref.watch(
        groupTransactionsProvider(groupId).future,
      );
      final posts = await ref.watch(
        groupCommunityPostsProvider(groupId).future,
      );
      final photos = <GroupAlbumPhoto>[
        ...transactions
            .where((transaction) => transaction.imagePath?.isNotEmpty == true)
            .map(
              (transaction) => GroupAlbumPhoto(
                imagePath: transaction.imagePath!,
                caption: transaction.caption,
                kind: 'receipt',
                date: transaction.createdAt,
                transactionId: transaction.id,
              ),
            ),
        ...posts.expand(
          (post) => post.media
              .where((media) => media.storagePath != null)
              .map(
                (media) => GroupAlbumPhoto(
                  imagePath: media.storagePath!,
                  caption: media.caption ?? post.content,
                  kind: media.kind,
                  date: media.createdAt,
                  postId: post.id,
                ),
              ),
        ),
      ]..sort((left, right) => right.date.compareTo(left.date));
      return List.unmodifiable(photos);
    });

class GroupPhotoAlbumScreen extends ConsumerStatefulWidget {
  const GroupPhotoAlbumScreen({required this.groupId, super.key});

  static const routePath = '/group-photo-album';
  final String groupId;

  @override
  ConsumerState<GroupPhotoAlbumScreen> createState() =>
      _GroupPhotoAlbumScreenState();
}

enum _AlbumFilter { all, receipts, memories }

class _GroupPhotoAlbumScreenState extends ConsumerState<GroupPhotoAlbumScreen> {
  _AlbumFilter _filter = _AlbumFilter.all;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(groupPhotoAlbumProvider(widget.groupId));
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(
        backgroundColor: colors.backgroundSoft,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.l10n.groupPhotoAlbumTitle),
        actions: [
          TextButton.icon(
            onPressed: _addPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(context.l10n.groupPhotoAlbumChoose),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _addPhotos,
            icon: const Icon(Icons.add_rounded),
            label: Text(context.l10n.groupPhotoAlbumAdd),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: _AlbumFilters(
              filter: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
          ),
          Expanded(
            child: photosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _MessageState(
                icon: Icons.photo_library_outlined,
                title: userFriendlyMessage(context, error),
                actionLabel: context.l10n.commonRetry,
                onAction: () =>
                    ref.invalidate(groupPhotoAlbumProvider(widget.groupId)),
              ),
              data: (photos) {
                final filtered = photos
                    .where(_matchesFilter)
                    .toList(growable: false);
                if (filtered.isEmpty) {
                  return _MessageState(
                    icon: Icons.photo_library_outlined,
                    title: context.l10n.groupPhotoAlbumEmpty,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(groupPhotoAlbumProvider(widget.groupId));
                    await ref.read(
                      groupPhotoAlbumProvider(widget.groupId).future,
                    );
                  },
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 7,
                          mainAxisSpacing: 7,
                          childAspectRatio: 0.86,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final photo = filtered[index];
                      return _AlbumPhotoTile(
                        photo: photo,
                        onTap: () => _openPhoto(photo),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(GroupAlbumPhoto photo) {
    switch (_filter) {
      case _AlbumFilter.all:
        return true;
      case _AlbumFilter.receipts:
        return photo.kind == 'receipt';
      case _AlbumFilter.memories:
        return photo.kind == 'memory';
    }
  }

  Future<void> _addPhotos() async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.groupPhotoAlbumAddHint,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, 'memory'),
                      child: Text(context.l10n.groupPhotoAlbumMemories),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, 'receipt'),
                      child: Text(context.l10n.groupPhotoAlbumReceipts),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (kind == null || !mounted) return;
    final images = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (images.isEmpty || !mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .createCommunityPost(
            groupId: widget.groupId,
            type: 'photo',
            media: [
              for (final image in images.take(9))
                GroupCommunityMediaDraft(localPath: image.path, kind: kind),
            ],
          );
      ref.invalidate(groupPhotoAlbumProvider(widget.groupId));
      ref.invalidate(groupCommunityPostsProvider(widget.groupId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupPhotoAlbumUploadSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  void _openPhoto(GroupAlbumPhoto photo) {
    if (photo.transactionId != null) {
      context.push(
        GroupRoutePaths.transactionDetail(
          groupId: widget.groupId,
          transactionId: photo.transactionId!,
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.groupPhotoAlbumPreview),
        content: AspectRatio(
          aspectRatio: 1,
          child: InteractiveViewer(
            child: SupabaseImage(imagePath: photo.imagePath),
          ),
        ),
      ),
    );
  }
}

class _AlbumFilters extends StatelessWidget {
  const _AlbumFilters({required this.filter, required this.onChanged});

  final _AlbumFilter filter;
  final ValueChanged<_AlbumFilter> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _AlbumFilterButton(
          label: context.l10n.groupPhotoAlbumAll,
          selected: filter == _AlbumFilter.all,
          onTap: () => onChanged(_AlbumFilter.all),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _AlbumFilterButton(
          label: context.l10n.groupPhotoAlbumReceipts,
          selected: filter == _AlbumFilter.receipts,
          onTap: () => onChanged(_AlbumFilter.receipts),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _AlbumFilterButton(
          label: context.l10n.groupPhotoAlbumMemories,
          selected: filter == _AlbumFilter.memories,
          onTap: () => onChanged(_AlbumFilter.memories),
        ),
      ),
    ],
  );
}

class _AlbumFilterButton extends StatelessWidget {
  const _AlbumFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(42),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: selected
          ? context.moniaryColors.primary
          : context.moniaryColors.surface,
      foregroundColor: selected
          ? Colors.white
          : context.moniaryColors.textSecondary,
      side: BorderSide(
        color: selected
            ? context.moniaryColors.primary
            : context.moniaryColors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _AlbumPhotoTile extends StatelessWidget {
  const _AlbumPhotoTile({required this.photo, required this.onTap});

  final GroupAlbumPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SupabaseImage(imagePath: photo.imagePath),
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      photo.kind == 'receipt'
                          ? Icons.receipt_long_outlined
                          : Icons.photo_camera_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        photo.caption ??
                            (photo.kind == 'receipt'
                                ? context.l10n.groupPhotoAlbumReceipts
                                : context.l10n.groupPhotoAlbumMemories),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: context.moniaryColors.textDim),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center),
          if (onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class GroupAlbumPhoto {
  const GroupAlbumPhoto({
    required this.imagePath,
    required this.kind,
    required this.date,
    this.caption,
    this.transactionId,
    this.postId,
  });

  final String imagePath;
  final String kind;
  final DateTime date;
  final String? caption;
  final String? transactionId;
  final String? postId;
}
