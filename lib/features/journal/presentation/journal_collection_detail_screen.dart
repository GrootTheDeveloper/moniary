import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../../statistics/presentation/statistics_view.dart';
import '../../transactions/domain/models/transaction_entry.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';

class JournalCollectionDetailScreen extends ConsumerWidget {
  const JournalCollectionDetailScreen({required this.collectionId, super.key});

  static const routePath = '/journal/collection';

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(journalCollectionProvider(collectionId));
    return Scaffold(
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(userFriendlyMessage(context, error))),
        ),
        data: (collection) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              title: Text(collection.name),
              flexibleSpace: FlexibleSpaceBar(
                background: collection.coverImagePath == null
                    ? ColoredBox(
                        color: AppTheme.sage.withValues(alpha: 0.18),
                        child: const Icon(
                          Icons.collections_bookmark_outlined,
                          size: 52,
                        ),
                      )
                    : SupabaseImage(
                        imagePath: collection.coverImagePath,
                        fallbackIcon: Icons.collections_bookmark_outlined,
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              sliver: SliverToBoxAdapter(
                child: _CollectionSummary(collection: collection),
              ),
            ),
            if (collection.transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(context.l10n.journalCollectionNoTransactions),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: collection.transactions.length,
                  itemBuilder: (context, index) => _TransactionPhoto(
                    transaction: collection.transactions[index],
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: () => _chooseTransaction(context, ref, collection),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.journalAddTransaction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseTransaction(
    BuildContext context,
    WidgetRef ref,
    JournalCollectionSummary collection,
  ) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final transactions = await ref.read(statisticsMonthProvider(month).future);
    final existingIds = collection.transactions
        .map((transaction) => transaction.id)
        .toSet();
    final choices = transactions
        .where((transaction) => !existingIds.contains(transaction.id))
        .toList();
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<TransactionEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.l10n.journalChooseTransaction,
                style: context.moniaryTypography.displayMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: choices.length,
                itemBuilder: (context, index) {
                  final transaction = choices[index];
                  return MoniaryHairlineTile(
                    showTopDivider: index == 0,
                    onTap: () => Navigator.pop(context, transaction),
                    title: Text(
                      transaction.note?.trim().isNotEmpty == true
                          ? transaction.note!.trim()
                          : transaction.categoryName,
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(transaction.transactionDate),
                    ),
                    trailing: Text(formatVnd(transaction.amount)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    try {
      await ref
          .read(journalActionControllerProvider.notifier)
          .addTransaction(
            collectionId: collectionId,
            transactionId: selected.id,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.collection});

  final JournalCollectionSummary collection;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            collection.name,
            style: context.moniaryTypography.displayMedium,
          ),
        ),
        Text(
          formatVnd(collection.totalExpense),
          style: context.moniaryTypography.displaySmall.copyWith(
            color: context.moniaryColors.primary,
          ),
        ),
      ],
    );
  }
}

class _TransactionPhoto extends StatelessWidget {
  const _TransactionPhoto({required this.transaction});

  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SupabaseImage(
          imagePath: transaction.imagePath,
          borderRadius: BorderRadius.circular(18),
          fallbackIcon: Icons.receipt_long_outlined,
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 9,
          child: Text(
            formatVnd(transaction.amount),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: transaction.imagePath == null
                  ? context.moniaryColors.textPrimary
                  : Colors.white,
              shadows: transaction.imagePath == null
                  ? null
                  : const [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }
}
