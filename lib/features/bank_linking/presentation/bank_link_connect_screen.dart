import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/utils/error_helpers.dart';
import '../application/bank_link_controller.dart';
import '../domain/models/bank_institution.dart';

class BankLinkConnectScreen extends ConsumerStatefulWidget {
  const BankLinkConnectScreen({super.key});

  static const routePath = '/bank-linking/connect';

  @override
  ConsumerState<BankLinkConnectScreen> createState() =>
      _BankLinkConnectScreenState();
}

class _BankLinkConnectScreenState extends ConsumerState<BankLinkConnectScreen> {
  BankInstitution? _selected;
  bool _consentGiven = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final institutionsAsync = ref.watch(bankInstitutionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bankLinkConnectTitle)),
      body: ColoredBox(
        color: colors.background,
        child: institutionsAsync.when(
          data: (institutions) {
            if (institutions.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.bankLinkConnectEmpty,
                  style: TextStyle(color: colors.textDim),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              children: [
                ...institutions.map(
                  (institution) => _InstitutionTile(
                    institution: institution,
                    selected: _selected?.id == institution.id,
                    onTap: () => setState(() {
                      _selected = institution;
                      _consentGiven = false;
                    }),
                  ),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 20),
                  _ConsentCard(
                    institutionName: _selected!.name,
                    consentGiven: _consentGiven,
                    onChanged: (value) =>
                        setState(() => _consentGiven = value ?? false),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _consentGiven && !_isSubmitting ? _submit : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.l10n.bankLinkConnectConfirm),
                  ),
                ],
              ],
            );
          },
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                userFriendlyMessage(context, error),
                style: TextStyle(color: colors.danger),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          loading: () =>
              Center(child: CircularProgressIndicator(color: colors.primary)),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final selected = _selected;
    if (selected == null) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(bankLinkControllerProvider.notifier)
          .linkInstitution(
            institutionId: selected.id,
            consentToken: 'user-consent-${DateTime.now().toIso8601String()}',
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.bankLinkConnectSuccess(selected.name)),
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
      setState(() => _isSubmitting = false);
    }
  }
}

class _InstitutionTile extends StatelessWidget {
  const _InstitutionTile({
    required this.institution,
    required this.selected,
    required this.onTap,
  });

  final BankInstitution institution;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfaceRaised.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.primary : colors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_outlined, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  institution.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_outlined
                    : Icons.radio_button_unchecked_outlined,
                color: selected ? colors.primary : colors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.institutionName,
    required this.consentGiven,
    required this.onChanged,
  });

  final String institutionName;
  final bool consentGiven;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.bankLinkConnectConsentTitle} $institutionName',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.bankLinkConnectConsentBody,
            style: TextStyle(color: colors.textDim),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: consentGiven,
            onChanged: onChanged,
            title: Text(context.l10n.bankLinkConnectConfirm),
          ),
        ],
      ),
    );
  }
}
