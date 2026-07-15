import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/queries/transaction_queries.dart';
import '../detail/day_detail_screen.dart';
import '../detail/transaction_detail_screen.dart';
import '../detail/transaction_route_args.dart';

class StarredTransactionsScreen extends ConsumerWidget {
  const StarredTransactionsScreen({super.key});

  static const routePath = '/starred-transactions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starredAsync = ref.watch(starredTransactionsProvider);

    return Scaffold(
      backgroundColor: context.moniaryColors.background,
      appBar: AppBar(
        title: Text(context.l10n.starredTransactionsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: starredAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 64,
                    color: context.moniaryColors.textSecondary.withValues(
                      alpha: 0.28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.starredTransactionsEmpty,
                    style: TextStyle(
                      color: context.moniaryColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return TransactionGridTile(
                    transaction: tx,
                    onTap: () => context.push(
                      TransactionDetailScreen.routePath,
                      extra: TransactionDetailRouteArgs(
                        transaction: tx,
                        day: tx.transactionDate,
                      ),
                    ),
                  )
                  .animate(delay: (30 * index).ms)
                  .fade()
                  .slideY(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutQuad,
                    duration: 300.ms,
                  );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.mint),
        ),
        error: (error, stack) =>
            Center(child: Text(userFriendlyMessage(context, error))),
      ),
    );
  }
}
