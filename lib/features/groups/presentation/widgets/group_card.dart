import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../domain/entities/spending_group.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({required this.group, required this.onTap, super.key});

  final SpendingGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = group.currentUserBalance;
    final balanceText = balance == 0
        ? context.l10n.groupBalanceSettled
        : balance > 0
        ? context.l10n.groupBalanceOwes(formatVnd(balance))
        : context.l10n.groupBalanceReceives(formatVnd(balance.abs()));
    final balanceColor = balance == 0
        ? AppTheme.success
        : balance > 0
        ? AppTheme.danger
        : AppTheme.mintSoft;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SupabaseImage(
                imagePath: group.avatarPath,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(20),
                fallbackIcon: Icons.groups_2_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (group.hasUnresolvedSettlements)
                          _Badge(
                            text: context.l10n.groupUnresolvedBadge,
                            color: AppTheme.amber,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${context.l10n.groupMemberCount(group.memberCount)} • '
                      '${context.l10n.groupTotalSpent(formatVnd(group.totalSpent))}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      balanceText,
                      style: TextStyle(
                        color: balanceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
