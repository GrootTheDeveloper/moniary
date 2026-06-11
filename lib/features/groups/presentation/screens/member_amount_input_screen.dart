import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/group_controller.dart';

class MemberAmountInputArgs {
  const MemberAmountInputArgs({
    required this.groupId,
    required this.transactionId,
    this.initialAmount = 0,
  });

  final String groupId;
  final String transactionId;
  final int initialAmount;
}

class MemberAmountInputScreen extends ConsumerStatefulWidget {
  const MemberAmountInputScreen({required this.args, super.key});

  static const routePath = '/groups/member-amount';

  final MemberAmountInputArgs args;

  @override
  ConsumerState<MemberAmountInputScreen> createState() =>
      _MemberAmountInputScreenState();
}

class _MemberAmountInputScreenState
    extends ConsumerState<MemberAmountInputScreen> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.args.initialAmount == 0
          ? ''
          : widget.args.initialAmount.toString(),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(groupActionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupAmountInputTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Text(context.l10n.groupTransactionPendingAmounts),
          const SizedBox(height: 18),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.groupAmountUsedLabel,
              suffixText: context.l10n.transactionAmountSuffix,
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: action.isLoading ? null : _submit,
            child: Text(
              action.isLoading
                  ? context.l10n.commonSaving
                  : context.l10n.groupAmountSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupAmountNonNegative)),
      );
      return;
    }
    try {
      await ref
          .read(groupActionControllerProvider.notifier)
          .submitMemberAmount(
            transactionId: widget.args.transactionId,
            groupId: widget.args.groupId,
            shareAmount: amount,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(context, error))),
      );
    }
  }
}
