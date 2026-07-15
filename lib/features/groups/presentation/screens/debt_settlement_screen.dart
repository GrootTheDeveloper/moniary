import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../domain/entities/group_settlement.dart';
import '../../domain/entities/spending_group.dart';
import '../../../profile/presentation/payment_qr_screen.dart';

class DebtSettlementScreen extends ConsumerWidget {
  const DebtSettlementScreen({required this.groupId, super.key});

  static const routePath = '/groups/settlements';

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(groupSettlementOverviewProvider(groupId));
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserId = ref.watch(currentGroupUserIdProvider);
    final colors = context.moniaryColors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.backgroundSoft,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.backgroundSoft,
        body: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: userFriendlyMessage(context, error),
            onRetry: () =>
                ref.invalidate(groupSettlementOverviewProvider(groupId)),
          ),
          data: (overview) => detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: userFriendlyMessage(context, error),
              onRetry: () => ref.invalidate(groupDetailProvider(groupId)),
            ),
            data: (detail) => _SettlementContent(
              overview: overview,
              detail: detail,
              currentUserId: currentUserId,
              onRefresh: () async {
                ref.invalidate(groupSettlementOverviewProvider(groupId));
                ref.invalidate(groupDetailProvider(groupId));
              },
              onConfirmAll: (items) =>
                  _confirmAllSettled(context, ref, currentUserId, items),
              onDispute: (item) => _dispute(context, ref, item),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAllSettled(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    List<GroupSettlementSuggestion> items,
  ) async {
    var handled = 0;
    try {
      final controller = ref.read(groupActionControllerProvider.notifier);
      for (final item in items) {
        if (item.status == GroupSettlementStatus.pending &&
            item.fromUserId == currentUserId) {
          await controller.markSettlementPaid(
            settlementId: item.id,
            groupId: groupId,
          );
          handled++;
        } else if (item.status == GroupSettlementStatus.payerMarkedPaid &&
            item.toUserId == currentUserId) {
          await controller.confirmSettlementReceived(
            settlementId: item.id,
            groupId: groupId,
          );
          handled++;
        }
      }
      if (handled == 0 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.groupSettlementWaitingForPayers)),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }

  Future<void> _dispute(
    BuildContext context,
    WidgetRef ref,
    GroupSettlementSuggestion item,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.groupSettlementDisputeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: context.l10n.groupSettlementDisputeReasonHint,
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
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .disputeSettlement(
            settlementId: item.id,
            groupId: groupId,
            reason: reason,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _SettlementContent extends StatelessWidget {
  const _SettlementContent({
    required this.overview,
    required this.detail,
    required this.currentUserId,
    required this.onRefresh,
    required this.onConfirmAll,
    required this.onDispute,
  });

  final GroupSettlementOverview overview;
  final SpendingGroupDetail detail;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<GroupSettlementSuggestion> items)
  onConfirmAll;
  final ValueChanged<GroupSettlementSuggestion> onDispute;

  @override
  Widget build(BuildContext context) {
    final active =
        overview.suggestions
            .where((item) => item.status != GroupSettlementStatus.completed)
            .toList()
          ..sort((left, right) => left.amount.compareTo(right.amount));

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: RefreshIndicator(
            color: context.moniaryColors.primary,
            backgroundColor: context.moniaryColors.backgroundSoft,
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(31, 13, 31, 48),
              children: [
                _SettlementTopBar(title: context.l10n.groupSettleAction),
                const SizedBox(height: 17),
                Text(
                  context.l10n
                      .groupSettlementOptimizedSubtitle(
                        detail.group.name,
                        active.length,
                      )
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: context.moniaryTypography.metadata.copyWith(
                    color: context.moniaryColors.textDim,
                    letterSpacing: 2.45,
                  ),
                ),
                const SizedBox(height: 22),
                if (active.isEmpty)
                  _EmptySettlementCard(text: context.l10n.debtNoSettlement)
                else ...[
                  for (var index = 0; index < active.length; index++) ...[
                    _SettlementCard(
                      item: active[index],
                      currentUserId: currentUserId,
                      fromAvatarPath: _avatarFor(active[index].fromUserId),
                      toAvatarPath: _avatarFor(active[index].toUserId),
                      toQrPath: _paymentQrFor(active[index].toUserId),
                      onDispute: () => onDispute(active[index]),
                    ),
                    if (index != active.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: () => onConfirmAll(active),
                      child: Text(context.l10n.groupSettlementConfirmAll),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _avatarFor(String userId) {
    for (final member in detail.members) {
      if (member.userId == userId) return member.avatarPath;
    }
    return null;
  }

  String? _paymentQrFor(String userId) {
    for (final member in detail.members) {
      if (member.userId == userId) return member.paymentQrPath;
    }
    return null;
  }
}

class _SettlementTopBar extends StatelessWidget {
  const _SettlementTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(
              onTap: () => context.pop(),
              label: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          Text(
            title,
            style: context.moniaryTypography.displaySmall.copyWith(
              fontSize: 20,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withValues(alpha: 0.8)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 22,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettlementCard extends ConsumerWidget {
  const _SettlementCard({
    required this.item,
    required this.currentUserId,
    required this.fromAvatarPath,
    required this.toAvatarPath,
    required this.toQrPath,
    required this.onDispute,
  });

  final GroupSettlementSuggestion item;
  final String currentUserId;
  final String? fromAvatarPath;
  final String? toAvatarPath;
  final String? toQrPath;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.fromLTRB(17, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.outline.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _MemberFace(
                imagePath: fromAvatarPath,
                fallbackColor: const Color(0xFF91A092),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 67,
                child: Text(
                  _displayName(context, item.fromUserId, item.fromDisplayName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '→',
                    style: context.moniaryTypography.displaySmall.copyWith(
                      color: colors.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              _MemberFace(
                imagePath: toAvatarPath,
                fallbackColor: const Color(0xFFB8AEA2),
              ),
              const SizedBox(width: 12),
              Text(
                _displayName(context, item.toUserId, item.toDisplayName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                ref.formatAmount(item.amount),
                style: context.moniaryTypography.metadataStrong.copyWith(
                  color: colors.textPrimary,
                  fontSize: 11,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (item.status != GroupSettlementStatus.disputed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDispute,
                icon: const Icon(Icons.report_problem_outlined, size: 16),
                label: Text(context.l10n.groupSettlementDisputeAction),
              ),
            ),
          if (item.fromUserId == currentUserId && toQrPath != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(
                  PaymentQrScreen.routePath,
                  extra: PaymentQrRouteArgs(
                    imagePath: toQrPath,
                    name: _displayName(
                      context,
                      item.toUserId,
                      item.toDisplayName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2_outlined, size: 16),
                label: Text(context.l10n.paymentQrViewForPayment),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _displayName(BuildContext context, String userId, String? name) {
    if (userId == currentUserId) return context.l10n.groupSettlementYou;
    return name ?? context.l10n.groupUnknownMember;
  }
}

class _MemberFace extends StatelessWidget {
  const _MemberFace({required this.imagePath, required this.fallbackColor});

  final String? imagePath;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SupabaseImage(
        imagePath: imagePath,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        fallbackBuilder: (_) => ColoredBox(color: fallbackColor),
      ),
    );
  }
}

class _EmptySettlementCard extends StatelessWidget {
  const _EmptySettlementCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MoniaryEditorialCard(
      radius: 13,
      backgroundColor: context.moniaryColors.surface.withValues(alpha: 0.72),
      child: Text(text),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
