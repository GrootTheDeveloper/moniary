import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatting_ref.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/moniary_design.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import 'group_route_paths.dart';
import '../widgets/group_transaction_filter_bar.dart';

class GroupTransactionsScreen extends ConsumerStatefulWidget {
  const GroupTransactionsScreen({required this.groupId, super.key});

  static const routePath = '/group-transactions';

  final String groupId;

  @override
  ConsumerState<GroupTransactionsScreen> createState() =>
      _GroupTransactionsScreenState();
}

class _GroupTransactionsScreenState
    extends ConsumerState<GroupTransactionsScreen> {
  static const _pageSize = 20;

  String _query = '';
  GroupSplitStatus? _status;
  int _offset = 0;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_status) {
      GroupSplitStatus.posted => 'posted',
      null => null,
      _ => 'pending',
    };
    final key = (
      groupId: widget.groupId,
      offset: _offset,
      limit: _pageSize,
      query: _query,
      status: status,
    );
    final pageAsync = ref.watch(groupTransactionsPageProvider(key));
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final memberCount = detailAsync.asData?.value.activeMembers.length ?? 0;

    return Scaffold(
      backgroundColor: context.moniaryColors.backgroundSoft,
      appBar: AppBar(title: Text(context.l10n.groupTransactionsTitle)),
      body: RefreshIndicator(
        color: context.moniaryColors.primary,
        backgroundColor: context.moniaryColors.backgroundSoft,
        onRefresh: () async {
          ref.invalidate(groupTransactionsPageProvider(key));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              context.l10n.groupTransactionExplorerSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.moniaryColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_outlined),
                hintText: context.l10n.groupTransactionSearchHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            GroupTransactionFilterBar(
              value: _status,
              onChanged: (value) => setState(() {
                _status = value;
                _offset = 0;
              }),
            ),
            const SizedBox(height: 12),
            if (pageAsync.isLoading && pageAsync.asData == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pageAsync.hasError)
              _ExplorerMessage(
                message: userFriendlyMessage(context, pageAsync.error!),
                onRetry: () =>
                    ref.invalidate(groupTransactionsPageProvider(key)),
              )
            else if (pageAsync.asData?.value.items.isEmpty ?? true)
              _ExplorerEmpty(
                text: _query.trim().isEmpty && _status == null
                    ? context.l10n.groupTransactionNoData
                    : context.l10n.groupTransactionFilterNoResults,
              )
            else ...[
              for (final transaction in pageAsync.asData!.value.items)
                _ExplorerTransactionRow(
                  transaction: transaction,
                  memberCount: memberCount,
                  onTap: () => context.push(
                    GroupRoutePaths.transactionDetail(
                      groupId: widget.groupId,
                      transactionId: transaction.id,
                    ),
                  ),
                ),
              if (pageAsync.asData!.value.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _offset += _pageSize),
                    icon: const Icon(Icons.expand_more_outlined),
                    label: Text(context.l10n.groupTransactionLoadMore),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _offset = 0;
      });
    });
  }
}

class _ExplorerTransactionRow extends ConsumerWidget {
  const _ExplorerTransactionRow({
    required this.transaction,
    required this.memberCount,
    required this.onTap,
  });

  final GroupTransaction transaction;
  final int memberCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    final payerName = transaction.creatorName?.trim().isNotEmpty == true
        ? transaction.creatorName!
        : context.l10n.groupUnknownMember;
    final isPending = transaction.splitStatus != GroupSplitStatus.posted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SupabaseImage(
                  imagePath: transaction.imagePath,
                  width: 46,
                  height: 46,
                  borderRadius: BorderRadius.circular(12),
                  fallbackBuilder: (_) => const _ReceiptFallback(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.caption?.trim().isNotEmpty == true
                            ? transaction.caption!
                            : transaction.categoryName ??
                                  context.l10n.groupNoCategory,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.groupTransactionHistorySubtitle(
                          payerName,
                          memberCount,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.moniaryTypography.metadata.copyWith(
                          color: colors.textDim,
                          fontSize: 9,
                        ),
                      ),
                      if (isPending)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            context.l10n.groupTransactionPendingShort,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.warning),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ref.formatAmount(transaction.totalAmount),
                  textAlign: TextAlign.end,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptFallback extends StatelessWidget {
  const _ReceiptFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppTheme.amber.withValues(alpha: 0.22),
    child: Icon(
      Icons.receipt_long_outlined,
      color: context.moniaryColors.primary,
    ),
  );
}

class _ExplorerEmpty extends StatelessWidget {
  const _ExplorerEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      MoniaryEditorialCard(child: Text(text, textAlign: TextAlign.center));
}

class _ExplorerMessage extends StatelessWidget {
  const _ExplorerMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MoniaryEditorialCard(
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}
