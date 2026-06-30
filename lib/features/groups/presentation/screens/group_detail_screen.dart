import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../application/group_controller.dart';
import '../../domain/entities/group_enums.dart';
import '../../domain/entities/group_transaction.dart';
import 'add_group_transaction_screen.dart';
import 'debt_settlement_screen.dart';
import 'group_transaction_detail_screen.dart';
import 'invite_member_screen.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  static const routePath = '/group-detail';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupDetailTitle)),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: userFriendlyMessage(context, error),
          onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
        ),
        data: (detail) {
          final transactionsAsync = ref.watch(
            groupTransactionsProvider(groupId),
          );
          final settlementsAsync = ref.watch(
            groupSettlementOverviewProvider(groupId),
          );
          final currencyCode = ref.watch(preferredCurrencyProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupDetailProvider(groupId));
              ref.invalidate(groupTransactionsProvider(groupId));
              ref.invalidate(groupSettlementOverviewProvider(groupId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _GroupHeader(
                  name: detail.group.name,
                  type: detail.group.type,
                  description: detail.group.description,
                  avatarPath: detail.group.avatarPath,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (detail.canInvite)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            InviteMemberScreen.routePath,
                            extra: groupId,
                          ),
                          icon: const Icon(Icons.person_add_outlined),
                          label: Text(context.l10n.groupInviteTitle),
                        ),
                      ),
                    if (detail.canInvite) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: detail.activeMembers.isEmpty
                            ? null
                            : () => context.push(
                                AddGroupTransactionScreen.routePath,
                                extra: AddGroupTransactionArgs(
                                  groupId: groupId,
                                ),
                              ),
                        icon: const Icon(Icons.add_outlined),
                        label: Text(context.l10n.groupAddTransaction),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  context.l10n.groupOverviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                transactionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.groupTransactionLoadError),
                  data: (transactions) => _OverviewCards(
                    totalSpent: transactions
                        .where(
                          (transaction) =>
                              transaction.splitStatus ==
                              GroupSplitStatus.posted,
                        )
                        .fold<int>(
                          0,
                          (sum, transaction) => sum + transaction.totalAmount,
                        ),
                    memberCount: detail.activeMembers.length,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.groupDebtAreaTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        DebtSettlementScreen.routePath,
                        extra: groupId,
                      ),
                      child: Text(context.l10n.commonViewAll),
                    ),
                  ],
                ),
                settlementsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.debtLoadError),
                  data: (overview) {
                    final unresolved = overview.suggestions
                        .where(
                          (item) =>
                              item.status != GroupSettlementStatus.completed,
                        )
                        .take(3)
                        .toList();
                    if (unresolved.isEmpty) {
                      return _Notice(
                        text: context.l10n.groupSettlementEmpty,
                        color: AppTheme.success,
                      );
                    }
                    return Column(
                      children: unresolved
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.swap_horiz_outlined,
                                color: AppTheme.amber,
                              ),
                              title: Text(
                                context.l10n.groupSettlementFromTo(
                                  item.fromDisplayName ??
                                      context.l10n.groupUnknownMember,
                                  item.toDisplayName ??
                                      context.l10n.groupUnknownMember,
                                ),
                              ),
                              trailing: Text(
                                formatCurrency(
                                  item.amount,
                                  currencyCode: currencyCode,
                                  locale: Localizations.localeOf(
                                    context,
                                  ).toString(),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  context.l10n.groupTransactionsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text(context.l10n.groupTransactionLoadError),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return _Notice(
                        text: context.l10n.groupTransactionNoData,
                        color: AppTheme.mintSoft,
                      );
                    }
                    return Column(
                      children: transactions
                          .map(
                            (transaction) => _TransactionCard(
                              transaction: transaction,
                              onTap: () => context.push(
                                GroupTransactionDetailScreen.routePath,
                                extra: transaction.id,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 26),
                Text(
                  context.l10n.groupMembersHeader,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...detail.members.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.surfaceRaised,
                      child: const Icon(Icons.person_outline),
                    ),
                    title: Text(member.resolvedName),
                    subtitle: Text(
                      member.status == GroupMemberStatus.active
                          ? context.l10n.groupMemberActive
                          : context.l10n.groupMemberInvited,
                    ),
                    trailing: Text(member.role.value),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _leaveGroup(context, ref),
                  icon: const Icon(Icons.logout_outlined),
                  label: Text(context.l10n.groupLeave),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupLeaveConfirmTitle),
        content: Text(context.l10n.groupLeaveConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.groupLeave),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .leaveGroup(groupId);
      if (!context.mounted) return;
      context.go('/groups');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.name,
    required this.type,
    required this.description,
    required this.avatarPath,
  });

  final String name;
  final String? type;
  final String? description;
  final String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SupabaseImage(
          imagePath: avatarPath,
          width: 88,
          height: 88,
          borderRadius: BorderRadius.circular(28),
          fallbackIcon: Icons.groups_2_outlined,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineMedium),
              if (type?.isNotEmpty == true) ...[
                const SizedBox(height: 5),
                Text(type!, style: const TextStyle(color: AppTheme.mintSoft)),
              ],
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 7),
                Text(description!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewCards extends ConsumerWidget {
  const _OverviewCards({required this.totalSpent, required this.memberCount});

  final int totalSpent;
  final int memberCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(preferredCurrencyProvider);
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.payments_outlined,
            label: context.l10n.groupTransactionTotal,
            value: formatCurrency(
              totalSpent,
              currencyCode: currencyCode,
              locale: Localizations.localeOf(context).toString(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.people_outline,
            label: context.l10n.groupMembersHeader,
            value: memberCount.toString(),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.mintSoft),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _TransactionCard extends ConsumerWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final GroupTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(preferredCurrencyProvider);
    final status = switch (transaction.splitStatus) {
      GroupSplitStatus.posted => context.l10n.groupTransactionPostedStatus,
      GroupSplitStatus.amountMismatch =>
        context.l10n.groupTransactionMismatchStatus,
      _ => context.l10n.groupTransactionPendingStatus,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: SupabaseImage(
          imagePath: transaction.imagePath,
          width: 54,
          height: 54,
          borderRadius: BorderRadius.circular(16),
          fallbackIcon: Icons.receipt_long_outlined,
        ),
        title: Text(
          transaction.caption?.isNotEmpty == true
              ? transaction.caption!
              : transaction.categoryName ?? context.l10n.groupNoCategory,
        ),
        subtitle: Text(
          '$status • ${DateFormat('dd/MM/yyyy HH:mm', Localizations.localeOf(context).toString()).format(transaction.transactionDate)}',
        ),
        trailing: Text(
          formatCurrency(
            transaction.totalAmount,
            currencyCode: currencyCode,
            locale: Localizations.localeOf(context).toString(),
          ),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}
