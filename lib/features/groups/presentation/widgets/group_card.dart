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
    final colors = context.moniaryColors;
    final typography = context.moniaryTypography;
    final balance = group.currentUserBalance;
    final balanceText = balance == 0
        ? context.l10n.groupBalanceSettled
        : balance > 0
        ? context.l10n.groupBalanceOwes(formatVnd(balance))
        : context.l10n.groupBalanceReceives(formatVnd(balance.abs()));
    final balanceColor = balance == 0
        ? colors.success
        : balance > 0
        ? colors.danger
        : colors.success;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SupabaseImage(
                imagePath: group.avatarPath,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(18),
                fallbackIcon: Icons.groups_2_outlined,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (group.hasUnresolvedSettlements)
                          _Badge(
                            text: context.l10n.groupUnresolvedBadge,
                            color: colors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.l10n.groupMemberCount(group.memberCount)} · '
                      '${context.l10n.groupTotalSpent(formatVnd(group.totalSpent))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.metadata.copyWith(
                        color: colors.textDim,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balanceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.metadataStrong.copyWith(
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_outlined, color: colors.textDim),
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
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.moniaryColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
