import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_transaction.dart';
import 'group_transaction_detail_screen.dart';

/// Gallery of every group transaction that carries an uploaded image.
///
/// Purely a read-only view built on top of the existing
/// [groupTransactionsProvider] — no dedicated backend is required.
class GroupPhotoAlbumScreen extends ConsumerWidget {
  const GroupPhotoAlbumScreen({required this.groupId, super.key});

  static const routePath = '/groups/photo-album';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(groupTransactionsProvider(groupId));
    final colors = context.moniaryColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupPhotoAlbumTitle)),
      body: transactionsAsync.when(
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
        data: (transactions) {
          final photos = transactions
              .where((transaction) => transaction.imagePath?.isNotEmpty == true)
              .toList(growable: false);

          return RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.backgroundSoft,
            onRefresh: () async =>
                ref.invalidate(groupTransactionsProvider(groupId)),
            child: photos.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 360,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 44,
                                color: colors.textDim,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.groupPhotoAlbumEmpty,
                                style: TextStyle(color: colors.textDim),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) =>
                        _PhotoTile(transaction: photos[index]),
                  ),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.transaction});

  final GroupTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final caption = transaction.caption?.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(
        GroupTransactionDetailScreen.routePath,
        extra: transaction.id,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SupabaseImage(
              imagePath: transaction.imagePath,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (caption?.isNotEmpty == true)
                      Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      formatMoney(transaction.totalAmount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
