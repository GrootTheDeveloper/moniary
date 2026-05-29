import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extension.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../privacy/privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class PolicyAcceptanceNoticeScreen extends StatelessWidget {
  const PolicyAcceptanceNoticeScreen({super.key});

  static const routePath = '/policy-acceptance-notice';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.legalPolicyAcceptance)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _AcceptanceHero(),
            const SizedBox(height: 16),
            const _AcceptanceCard(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push(PrivacyPolicyScreen.routePath),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(context.l10n.legalViewPrivacyPolicy),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(TermsOfUseScreen.routePath),
              icon: const Icon(Icons.gavel_outlined),
              label: Text(context.l10n.legalViewTermsOfUse),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptanceHero extends StatelessWidget {
  const _AcceptanceHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        'Thông báo này giúp người dùng hiểu rằng các chính sách hiện tại áp dụng khi tiếp tục sử dụng Moniary.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _AcceptanceCard extends StatelessWidget {
  const _AcceptanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Khi tiếp tục dùng Moniary, người dùng xác nhận đã có cơ hội đọc Chính sách bảo mật, Điều khoản sử dụng, thông báo lưu giữ dữ liệu và các ghi chú an toàn liên quan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
