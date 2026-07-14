import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import 'group_transaction_detail_screen.dart';

final groupPhotoAlbumProvider =
    FutureProvider.family<List<_GroupAlbumPhoto>, String>((ref, groupId) async {
      final transactions = await ref.watch(
        groupTransactionsProvider(groupId).future,
      );
      return transactions
          .where((transaction) => transaction.imagePath?.isNotEmpty == true)
          .map(
            (transaction) => _GroupAlbumPhoto(
              transactionId: transaction.id,
              imagePath: transaction.imagePath!,
              caption: transaction.caption ?? transaction.categoryName,
              creatorName: transaction.creatorName,
              date: transaction.transactionDate,
            ),
          )
          .toList(growable: false);
    });

class GroupPhotoAlbumScreen extends ConsumerWidget {
  const GroupPhotoAlbumScreen({required this.groupId, super.key});

  static const routePath = '/group-photo-album';
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(groupPhotoAlbumProvider(groupId));
    final colors = context.moniaryColors;
    return Scaffold(
      backgroundColor: colors.backgroundSoft,
      appBar: AppBar(
        title: Text(context.l10n.groupPhotoAlbumTitle),
        backgroundColor: colors.backgroundSoft,
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _MessageState(
          icon: Icons.photo_library_outlined,
          title: context.l10n.groupPhotoAlbumLoadError,
          actionLabel: context.l10n.commonRetry,
          onAction: () => ref.invalidate(groupPhotoAlbumProvider(groupId)),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return _MessageState(
              icon: Icons.photo_library_outlined,
              title: context.l10n.groupPhotoAlbumEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(groupPhotoAlbumProvider(groupId)),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
                childAspectRatio: .78,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push(
                    GroupTransactionDetailScreen.routePath,
                    extra: photo.transactionId,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SupabaseImage(
                          imagePath: photo.imagePath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        photo.caption ?? context.l10n.groupTransactionFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${photo.creatorName ?? context.l10n.groupMemberFallback} • ${DateFormat('dd/MM/yyyy').format(photo.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSubtle,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
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

class _GroupAlbumPhoto {
  const _GroupAlbumPhoto({
    required this.transactionId,
    required this.imagePath,
    required this.caption,
    required this.creatorName,
    required this.date,
  });

  final String transactionId;
  final String imagePath;
  final String? caption;
  final String? creatorName;
  final DateTime date;
}
