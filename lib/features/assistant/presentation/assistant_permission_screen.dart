import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../application/assistant_controller.dart';
import '../domain/assistant_models.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import 'assistant_conversation_screen.dart';

class AssistantPermissionScreen extends ConsumerStatefulWidget {
  const AssistantPermissionScreen({super.key});

  static const routePath = '/assistant/permissions';

  @override
  ConsumerState<AssistantPermissionScreen> createState() =>
      _AssistantPermissionScreenState();
}

class _AssistantPermissionScreenState
    extends ConsumerState<AssistantPermissionScreen> {
  bool _loadedAccess = false;
  bool _enabled = true;
  bool _transactions = true;
  bool _wallets = true;
  bool _budgets = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentAccess());
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(assistantAccessControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? const BackButton()
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go(CalendarScreen.routePath),
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 18),
        child: FilledButton(
          onPressed: action.isLoading ? null : _confirm,
          child: action.isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.assistantPermissionConfirm),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        children: [
          Text(
            context.l10n.assistantPermissionTitle,
            style: context.moniaryTypography.displayLarge,
          ),
          const SizedBox(height: 10),
          _DateRangeNote(text: context.l10n.assistantPermissionDateRange),
          const SizedBox(height: 22),
          MoniaryEditorialCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: context.moniaryColors.surface,
            borderColor: context.moniaryColors.outline,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.l10n.assistantAnalyzeAll,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              value: _enabled,
              onChanged: (value) => setState(() {
                _enabled = value;
                _transactions = value;
                _wallets = value;
                _budgets = value;
              }),
            ),
          ),
          const SizedBox(height: 14),
          _PermissionTile(
            icon: Icons.receipt_long_outlined,
            title: context.l10n.assistantTransactionsAccess,
            body: context.l10n.assistantTransactionsAccessBody,
            value: _transactions,
            enabled: _enabled,
            onChanged: (value) => setState(() => _transactions = value),
          ),
          _PermissionTile(
            icon: Icons.account_balance_wallet_outlined,
            title: context.l10n.assistantWalletsAccess,
            body: context.l10n.assistantWalletsAccessBody,
            value: _wallets,
            enabled: _enabled,
            onChanged: (value) => setState(() => _wallets = value),
          ),
          _PermissionTile(
            icon: Icons.tune,
            title: context.l10n.assistantBudgetsAccess,
            body: context.l10n.assistantBudgetsAccessBody,
            value: _budgets,
            enabled: _enabled,
            onChanged: (value) => setState(() => _budgets = value),
          ),
          _PermissionTile(
            icon: Icons.savings_outlined,
            title: context.l10n.assistantSavingsAccess,
            body: context.l10n.assistantSavingsAccessBody,
            value: false,
            enabled: false,
            badge: context.l10n.assistantUpcomingBadge,
            onChanged: null,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: context.moniaryColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.assistantPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrentAccess() async {
    if (_loadedAccess) return;
    try {
      final access = await ref.read(assistantAccessProvider.future);
      if (!mounted) return;
      setState(() {
        _loadedAccess = true;
        _enabled = access.enabled;
        _transactions = access.transactions;
        _wallets = access.wallets;
        _budgets = access.budgets;
      });
    } catch (_) {
      if (mounted) setState(() => _loadedAccess = true);
    }
  }

  Future<void> _confirm() async {
    try {
      await ref
          .read(assistantAccessControllerProvider.notifier)
          .save(
            AssistantAccess(
              introSeen: true,
              enabled: _enabled,
              transactions: _transactions,
              wallets: _wallets,
              budgets: _budgets,
            ),
          );
      if (!mounted) return;
      context.go(
        _enabled
            ? AssistantConversationScreen.routePath
            : AssistantPermissionScreen.routePath,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final active = enabled && onChanged != null;
    return MoniaryHairlineTile(
      leading: Icon(icon, color: active ? colors.primary : colors.textDim),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            _UpcomingBadge(label: badge!),
          ],
        ],
      ),
      subtitle: Text(body),
      trailing: onChanged == null
          ? Icon(Icons.lock_outline, size: 18, color: colors.textDim)
          : Switch(value: value, onChanged: enabled ? onChanged : null),
    );
  }
}

class _DateRangeNote extends StatelessWidget {
  const _DateRangeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBadge extends StatelessWidget {
  const _UpcomingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.textDim.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: context.moniaryTypography.metadataStrong.copyWith(
          color: colors.textDim,
          fontSize: 10,
        ),
      ),
    );
  }
}
