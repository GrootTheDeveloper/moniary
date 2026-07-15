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
import '../widgets/settlement_action_button.dart';

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
              groupId: groupId,
              overview: overview,
              detail: detail,
              currentUserId: currentUserId,
              onRefresh: () async {
                await Future.wait<Object?>([
                  ref.refresh(groupSettlementOverviewProvider(groupId).future),
                  ref.refresh(groupDetailProvider(groupId).future),
                ]);
              },
              onConfirmAll: (items) =>
                  _confirmAllSettled(context, ref, currentUserId, items),
              onDispute: (item) => _dispute(context, ref, item),
              onResetDispute: (item) => _resetDispute(context, ref, item),
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
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _DisputeReasonDialog(),
    );
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

  Future<void> _resetDispute(
    BuildContext context,
    WidgetRef ref,
    GroupSettlementSuggestion item,
  ) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groupSettlementResetDisputeTitle),
        content: Text(context.l10n.groupSettlementResetDisputeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.groupSettlementResetDisputeAction),
          ),
        ],
      ),
    );
    if (shouldReset != true || !context.mounted) return;
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .resetDisputedSettlement(settlementId: item.id, groupId: groupId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}

class _DisputeReasonDialog extends StatefulWidget {
  const _DisputeReasonDialog();

  @override
  State<_DisputeReasonDialog> createState() => _DisputeReasonDialogState();
}

class _DisputeReasonDialogState extends State<_DisputeReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.groupSettlementDisputeTitle),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(value.text.trim()),
            child: Text(context.l10n.commonConfirm),
          ),
        ),
      ],
    );
  }
}

class _SettlementContent extends ConsumerWidget {
  const _SettlementContent({
    required this.groupId,
    required this.overview,
    required this.detail,
    required this.currentUserId,
    required this.onRefresh,
    required this.onConfirmAll,
    required this.onDispute,
    required this.onResetDispute,
  });

  final String groupId;
  final GroupSettlementOverview overview;
  final SpendingGroupDetail detail;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<GroupSettlementSuggestion> items)
  onConfirmAll;
  final Future<void> Function(GroupSettlementSuggestion) onDispute;
  final Future<void> Function(GroupSettlementSuggestion) onResetDispute;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SettlementContentBody(
    groupId: groupId,
    overview: overview,
    detail: detail,
    currentUserId: currentUserId,
    onRefresh: onRefresh,
    onConfirmAll: onConfirmAll,
    onDispute: onDispute,
    onResetDispute: onResetDispute,
  );
}

enum _SettlementScope { group, personal }

class _SettlementContentBody extends ConsumerStatefulWidget {
  const _SettlementContentBody({
    required this.groupId,
    required this.overview,
    required this.detail,
    required this.currentUserId,
    required this.onRefresh,
    required this.onConfirmAll,
    required this.onDispute,
    required this.onResetDispute,
  });

  final String groupId;
  final GroupSettlementOverview overview;
  final SpendingGroupDetail detail;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<GroupSettlementSuggestion> items)
  onConfirmAll;
  final Future<void> Function(GroupSettlementSuggestion) onDispute;
  final Future<void> Function(GroupSettlementSuggestion) onResetDispute;

  @override
  ConsumerState<_SettlementContentBody> createState() =>
      _SettlementContentBodyState();
}

class _SettlementContentBodyState
    extends ConsumerState<_SettlementContentBody> {
  _SettlementScope _scope = _SettlementScope.personal;
  final Set<String> _busySettlementIds = <String>{};
  bool _batchBusy = false;

  @override
  Widget build(BuildContext context) {
    final scoped = widget.overview.suggestions.where((item) {
      if (_scope == _SettlementScope.group) return true;
      return item.fromUserId == widget.currentUserId ||
          item.toUserId == widget.currentUserId;
    }).toList();
    final completedCount = scoped
        .where((item) => item.status == GroupSettlementStatus.completed)
        .length;
    final active = scoped
      ..removeWhere((item) => item.status == GroupSettlementStatus.completed)
      ..sort((left, right) => left.amount.compareTo(right.amount));
    final actionable = active
        .where((item) {
          return (item.status == GroupSettlementStatus.pending &&
                  item.fromUserId == widget.currentUserId) ||
              (item.status == GroupSettlementStatus.payerMarkedPaid &&
                  item.toUserId == widget.currentUserId);
        })
        .toList(growable: false);
    final remainingAmount = active.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final payableAmount = active
        .where((item) => item.fromUserId == widget.currentUserId)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final receivableAmount = active
        .where((item) => item.toUserId == widget.currentUserId)
        .fold<int>(0, (sum, item) => sum + item.amount);
    final myPayable = active
        .where(
          (item) =>
              item.fromUserId == widget.currentUserId &&
              item.status != GroupSettlementStatus.disputed,
        )
        .toList(growable: false);
    final myReceivable = active
        .where(
          (item) =>
              item.toUserId == widget.currentUserId &&
              item.status != GroupSettlementStatus.disputed,
        )
        .toList(growable: false);
    final myDisputed = active
        .where(
          (item) =>
              item.status == GroupSettlementStatus.disputed &&
              (item.fromUserId == widget.currentUserId ||
                  item.toUserId == widget.currentUserId),
        )
        .toList(growable: false);
    final groupOpen = active
        .where((item) => item.status != GroupSettlementStatus.disputed)
        .toList(growable: false);
    final groupDisputed = active
        .where((item) => item.status == GroupSettlementStatus.disputed)
        .toList(growable: false);

    List<Widget> buildSection(
      String title,
      List<GroupSettlementSuggestion> items,
    ) {
      if (items.isEmpty) return const <Widget>[];
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: context.moniaryColors.textDim,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (var index = 0; index < items.length; index++) ...[
          _SettlementCard(
            item: items[index],
            currentUserId: widget.currentUserId,
            fromAvatarPath: _avatarFor(items[index].fromUserId),
            toAvatarPath: _avatarFor(items[index].toUserId),
            toQrPath: _paymentQrFor(items[index].toUserId),
            isBusy: _batchBusy || _busySettlementIds.contains(items[index].id),
            onDispute: () => _openDispute(items[index]),
            canResetDispute: widget.detail.canInvite,
            onResetDispute: () => _resetDispute(items[index]),
            onMarkPaid: () => _markPaid(items[index]),
            onConfirmReceived: () => _confirmReceived(items[index]),
          ),
          if (index != items.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
      ];
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: RefreshIndicator(
            color: context.moniaryColors.primary,
            backgroundColor: context.moniaryColors.backgroundSoft,
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(31, 13, 31, 48),
              children: [
                _SettlementTopBar(title: context.l10n.groupSettleAction),
                const SizedBox(height: 17),
                Text(
                  context.l10n
                      .groupSettlementOptimizedSubtitle(
                        widget.detail.group.name,
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
                SizedBox(
                  height: 42,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SettlementScopeButton(
                          icon: Icons.groups_outlined,
                          label: context.l10n.groupSettlementGroupOverview,
                          selected: _scope == _SettlementScope.group,
                          onTap: () =>
                              setState(() => _scope = _SettlementScope.group),
                        ),
                      ),
                      Expanded(
                        child: _SettlementScopeButton(
                          icon: Icons.person_outline,
                          label: context.l10n.groupSettlementMyPart,
                          selected: _scope == _SettlementScope.personal,
                          onTap: () => setState(
                            () => _scope = _SettlementScope.personal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SettlementSummaryCard(
                  completedCount: completedCount,
                  totalCount: scoped.length,
                  remainingAmount: remainingAmount,
                  formattedRemaining: ref.formatAmount(remainingAmount),
                  payableAmount: _scope == _SettlementScope.personal
                      ? ref.formatAmount(payableAmount)
                      : null,
                  receivableAmount: _scope == _SettlementScope.personal
                      ? ref.formatAmount(receivableAmount)
                      : null,
                  label: _scope == _SettlementScope.personal
                      ? context.l10n.groupSettlementMyProgress
                      : null,
                ),
                const SizedBox(height: 16),
                const _SettlementFlowCard(),
                const SizedBox(height: 18),
                if (active.isEmpty)
                  _EmptySettlementCard(text: context.l10n.debtNoSettlement)
                else ...[
                  ...(_scope == _SettlementScope.personal
                      ? [
                          ...buildSection(
                            context.l10n.groupSettlementMyToPay,
                            myPayable,
                          ),
                          ...buildSection(
                            context.l10n.groupSettlementMyToReceive,
                            myReceivable,
                          ),
                          ...buildSection(
                            context.l10n.groupSettlementDisputedSection,
                            myDisputed,
                          ),
                        ]
                      : [
                          ...buildSection(
                            context.l10n.groupSettlementGroupOpenItems,
                            groupOpen,
                          ),
                          ...buildSection(
                            context.l10n.groupSettlementDisputedSection,
                            groupDisputed,
                          ),
                        ]),
                  if (actionable.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _batchBusy
                            ? null
                            : () => _confirmAll(actionable),
                        icon: const Icon(Icons.done_all_rounded),
                        label: Text(
                          context.l10n.groupSettlementConfirmMyActions,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _avatarFor(String userId) {
    for (final member in widget.detail.members) {
      if (member.userId == userId) return member.avatarPath;
    }
    return null;
  }

  String? _paymentQrFor(String userId) {
    for (final member in widget.detail.members) {
      if (member.userId == userId) return member.paymentQrPath;
    }
    return null;
  }

  Future<void> _markPaid(GroupSettlementSuggestion item) async {
    await _runAction(
      item.id,
      () => ref
          .read(groupActionControllerProvider.notifier)
          .markSettlementPaid(settlementId: item.id, groupId: widget.groupId),
      context.l10n.groupSettlementMarkedPaid,
    );
  }

  Future<void> _confirmReceived(GroupSettlementSuggestion item) async {
    await _runAction(
      item.id,
      () => ref
          .read(groupActionControllerProvider.notifier)
          .confirmSettlementReceived(
            settlementId: item.id,
            groupId: widget.groupId,
          ),
      context.l10n.groupSettlementReceivedConfirmed,
    );
  }

  Future<void> _openDispute(GroupSettlementSuggestion item) async {
    await _runProtectedDialog(item.id, () => widget.onDispute(item));
  }

  Future<void> _resetDispute(GroupSettlementSuggestion item) async {
    await _runProtectedDialog(item.id, () => widget.onResetDispute(item));
  }

  Future<void> _runProtectedDialog(
    String settlementId,
    Future<void> Function() action,
  ) async {
    if (_batchBusy || _busySettlementIds.contains(settlementId)) return;
    setState(() => _busySettlementIds.add(settlementId));
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busySettlementIds.remove(settlementId));
    }
  }

  Future<void> _runAction(
    String settlementId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_batchBusy || _busySettlementIds.contains(settlementId)) return;
    setState(() => _busySettlementIds.add(settlementId));
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    } finally {
      if (mounted) setState(() => _busySettlementIds.remove(settlementId));
    }
  }

  Future<void> _confirmAll(List<GroupSettlementSuggestion> items) async {
    if (_batchBusy) return;
    setState(() => _batchBusy = true);
    try {
      await widget.onConfirmAll(items);
    } finally {
      if (mounted) setState(() => _batchBusy = false);
    }
  }
}

class _SettlementSummaryCard extends StatelessWidget {
  const _SettlementSummaryCard({
    required this.completedCount,
    required this.totalCount,
    required this.remainingAmount,
    required this.formattedRemaining,
    this.payableAmount,
    this.receivableAmount,
    this.label,
  });

  final int completedCount;
  final int totalCount;
  final int remainingAmount;
  final String formattedRemaining;
  final String? payableAmount;
  final String? receivableAmount;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final progress = totalCount == 0
        ? 1.0
        : (completedCount / totalCount).clamp(0.0, 1.0);
    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      backgroundColor: colors.surface.withValues(alpha: 0.84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: context.moniaryTypography.metadata.copyWith(
                color: colors.textDim,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.groupSettlementRemaining(formattedRemaining),
                  style: context.moniaryTypography.displaySmall.copyWith(
                    fontSize: 21,
                    color: remainingAmount == 0
                        ? colors.success
                        : colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                remainingAmount == 0
                    ? Icons.check_circle_outline
                    : Icons.swap_horiz_rounded,
                color: remainingAmount == 0 ? colors.success : colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.groupSettlementProgress(completedCount, totalCount),
            style: context.moniaryTypography.metadata.copyWith(
              color: colors.textDim,
            ),
          ),
          if (payableAmount != null && receivableAmount != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SettlementMetric(
                    label: context.l10n.groupSettlementMyToPay,
                    value: payableAmount!,
                  ),
                ),
                Expanded(
                  child: _SettlementMetric(
                    label: context.l10n.groupSettlementMyToReceive,
                    value: receivableAmount!,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.outline.withValues(alpha: 0.3),
              color: colors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementMetric extends StatelessWidget {
  const _SettlementMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.moniaryTypography.metadata.copyWith(
          color: context.moniaryColors.textDim,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: context.moniaryColors.textPrimary,
        ),
      ),
    ],
  );
}

class _SettlementFlowCard extends StatelessWidget {
  const _SettlementFlowCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return MoniaryEditorialCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      backgroundColor: colors.primary.withValues(alpha: 0.08),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sync_alt_rounded, color: colors.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.groupSettlementFlowTitle,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.groupSettlementFlowSummary,
                  style: context.moniaryTypography.metadata.copyWith(
                    color: colors.textDim,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: colors.primary, size: 18),
        ],
      ),
    );
  }
}

class _SettlementScopeButton extends StatelessWidget {
  const _SettlementScopeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelPadding: const EdgeInsets.symmetric(horizontal: 7),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    ),
  );
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
    required this.isBusy,
    required this.onDispute,
    required this.canResetDispute,
    required this.onResetDispute,
    required this.onMarkPaid,
    required this.onConfirmReceived,
  });

  final GroupSettlementSuggestion item;
  final String currentUserId;
  final String? fromAvatarPath;
  final String? toAvatarPath;
  final String? toQrPath;
  final bool isBusy;
  final VoidCallback onDispute;
  final bool canResetDispute;
  final VoidCallback onResetDispute;
  final VoidCallback onMarkPaid;
  final VoidCallback onConfirmReceived;

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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayName(context, item.fromUserId, item.fromDisplayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '→',
                style: context.moniaryTypography.displaySmall.copyWith(
                  color: colors.primary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              _MemberFace(
                imagePath: toAvatarPath,
                fallbackColor: const Color(0xFFB8AEA2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayName(context, item.toUserId, item.toDisplayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                child: Text(
                  ref.formatAmount(item.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: context.moniaryTypography.metadataStrong.copyWith(
                    color: colors.textPrimary,
                    fontSize: 11,
                    letterSpacing: 0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          if (item.fromUserId == currentUserId &&
              item.status == GroupSettlementStatus.pending) ...[
            const SizedBox(height: 10),
            _SettlementStatusHint(
              icon: Icons.payments_outlined,
              text: context.l10n.groupSettlementPayerActionHint,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: SettlementActionButton(
                status: item.status,
                isReceiverAction: false,
                onPressed: isBusy ? null : onMarkPaid,
              ),
            ),
          ] else if (item.toUserId == currentUserId &&
              item.status == GroupSettlementStatus.payerMarkedPaid) ...[
            const SizedBox(height: 10),
            _SettlementStatusHint(
              icon: Icons.verified_outlined,
              text: context.l10n.groupSettlementReceiverActionHint,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: SettlementActionButton(
                status: item.status,
                isReceiverAction: true,
                onPressed: isBusy ? null : onConfirmReceived,
              ),
            ),
          ] else if (item.fromUserId == currentUserId &&
              item.status == GroupSettlementStatus.payerMarkedPaid)
            _SettlementStatusHint(
              icon: Icons.hourglass_top_rounded,
              text: context.l10n.groupSettlementWaitingReceiver,
            )
          else if (item.toUserId == currentUserId &&
              item.status == GroupSettlementStatus.pending)
            _SettlementStatusHint(
              icon: Icons.hourglass_empty_rounded,
              text: context.l10n.groupSettlementWaitingPayer,
            )
          else if (item.status == GroupSettlementStatus.disputed) ...[
            _SettlementStatusHint(
              icon: Icons.report_problem_outlined,
              text: item.disputeReason?.trim().isNotEmpty == true
                  ? context.l10n.groupSettlementDisputeReason(
                      item.disputeReason!,
                    )
                  : context.l10n.groupSettlementDisputed,
            ),
            if (canResetDispute)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: isBusy ? null : onResetDispute,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text(context.l10n.groupSettlementResetDisputeAction),
                ),
              ),
          ],
          if (item.status != GroupSettlementStatus.disputed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isBusy ? null : onDispute,
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

class _SettlementStatusHint extends StatelessWidget {
  const _SettlementStatusHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.moniaryColors.textDim),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.moniaryColors.textDim,
            ),
          ),
        ),
      ],
    ),
  );
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
