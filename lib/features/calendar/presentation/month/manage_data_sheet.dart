import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../categories/presentation/category_section.dart';
import '../../../wallets/presentation/wallet_section.dart';

class ManageDataSheet extends StatelessWidget {
  const ManageDataSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.manageDataTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF9CB0C2),
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
