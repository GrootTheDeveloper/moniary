import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../categories/presentation/category_section.dart';
import '../../../wallets/presentation/wallet_section.dart';

class ManageDataSheet extends StatelessWidget {
  const ManageDataSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Container(
          color: colors.backgroundSoft,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.manageDataTitle,
                style: context.moniaryTypography.displaySmall,
              ),
              const SizedBox(height: 16),
              TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                labelColor: colors.background,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: context.l10n.walletTitle),
                  Tab(text: context.l10n.categoryTitle),
                ],
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 520,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(child: WalletSection()),
                    SingleChildScrollView(child: CategorySection()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
