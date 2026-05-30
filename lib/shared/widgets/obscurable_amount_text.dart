import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/application/privacy_controller.dart';

class ObscurableAmountText extends ConsumerWidget {
  final String amountText;
  final TextStyle? style;
  final String obscurePattern;
  final String? prefixText;
  final String? suffixText;

  const ObscurableAmountText({
    super.key,
    required this.amountText,
    this.style,
    this.obscurePattern = '***',
    this.prefixText,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(privacyControllerProvider.select((state) => state.isBalancesHidden));
    final displayAmount = isHidden ? obscurePattern : amountText;
    return Text(
      '${prefixText ?? ''}$displayAmount${suffixText ?? ''}',
      style: style,
    );
  }
}
