import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/error_helpers.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../../../shared/widgets/supabase_image.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';
import 'journal_collection_detail_screen.dart';

class JournalCollectionsScreen extends ConsumerWidget {
  const JournalCollectionsScreen({super.key});

  static const routePath = '/journal/collections';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(journalCollectionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.journalCollectionsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.journalCreateCollection,
            onPressed: () => _createCollection(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(userFriendlyMessage(context, error))),
        data: (collections) {
          if (collections.isEmpty) {
            return _CollectionEmpty(
              onCreate: () => _createCollection(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(journalCollectionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
              itemCount: collections.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == collections.length) {
                  return OutlinedButton.icon(
                    onPressed: () => _createCollection(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.journalCreateCollection),
                  );
                }
                final collection = collections[index];
                return _CollectionCard(
                  collection: collection,
                  onTap: () => context.push(
                    JournalCollectionDetailScreen.routePath,
                    extra: collection.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.journalCreateCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.journalCollectionName,
            hintText: context.l10n.journalCollectionNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(context.l10n.commonCreate),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      final id = await ref
          .read(journalActionControllerProvider.notifier)
          .createCollection(name: name);
      if (context.mounted) {
        await context.push(JournalCollectionDetailScreen.routePath, extra: id);
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final JournalCollectionSummary collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateRange = _dateRange(context);
    return MoniaryEditorialCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            width: double.infinity,
            child: collection.coverImagePath == null
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.sage.withValues(alpha: 0.18),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.collections_bookmark_outlined,
                        size: 42,
                      ),
                    ),
                  )
                : SupabaseImage(
                    imagePath: collection.coverImagePath,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    fallbackIcon: Icons.collections_bookmark_outlined,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: context.moniaryTypography.displaySmall,
                ),
                const SizedBox(height: 7),
                Text(
                  [
                    context.l10n.journalCollectionMeta(
                      collection.transactionCount,
                      formatVnd(collection.totalExpense),
                    ),
                    ?dateRange,
                  ].join(' · ').toUpperCase(),
                  style: context.moniaryTypography.metadata,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _dateRange(BuildContext context) {
    final start = collection.startDate;
    final end = collection.endDate;
    if (start == null && end == null) return null;
    final format = DateFormat.MMMd(Localizations.localeOf(context).toString());
    if (start != null && end != null) {
      return '${format.format(start)}–${format.format(end)}';
    }
    return format.format(start ?? end!);
  }
}

class _CollectionEmpty extends StatelessWidget {
  const _CollectionEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: MoniaryEditorialCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.collections_bookmark_outlined,
                size: 48,
                color: context.moniaryColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.journalCollectionEmptyTitle,
                style: context.moniaryTypography.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.journalCollectionEmptyBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onCreate,
                child: Text(context.l10n.journalCreateCollection),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
