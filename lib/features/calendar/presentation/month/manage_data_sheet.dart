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
      child: FractionallySizedBox(
        heightFactor: 0.64,
        alignment: Alignment.bottomCenter,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.backgroundSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 10, 28, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colors.textPrimary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.manageDataTitle,
                          style: context.moniaryTypography.displaySmall
                              .copyWith(fontSize: 18, height: 1.05),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            width: 176,
                            height: 36,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                colors.surfaceRaised,
                                colors.textPrimary,
                                0.04,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: TabBar(
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: colors.textPrimary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              labelColor: colors.background,
                              unselectedLabelColor: colors.textSecondary,
                              labelStyle: context
                                  .moniaryTypography
                                  .metadataStrong
                                  .copyWith(fontSize: 11, letterSpacing: 0),
                              unselectedLabelStyle: context
                                  .moniaryTypography
                                  .metadataStrong
                                  .copyWith(fontSize: 11, letterSpacing: 0),
                              tabs: [
                                Tab(text: context.l10n.manageDataWalletTab),
                                Tab(text: context.l10n.categoryTitle),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28, 0, 28, 18),
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(child: WalletSection()),
                        SingleChildScrollView(child: CategorySection()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
