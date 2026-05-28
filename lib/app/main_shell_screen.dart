import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import '../l10n/l10n_extension.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../features/calendar/application/month/calendar_month_provider.dart';
import '../features/calendar/application/month/calendar_visible_month_provider.dart';
import '../features/transactions/domain/models/transaction_mutation_result.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MoniaryTab currentTab;
    switch (navigationShell.currentIndex) {
      case 0:
        currentTab = MoniaryTab.calendar;
        break;
      case 1:
        currentTab = MoniaryTab.groups;
        break;
      case 2:
        currentTab = MoniaryTab.profile;
        break;
      default:
        currentTab = MoniaryTab.calendar;
    }

    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 66,
        height: 66,
        child: FloatingActionButton(
          backgroundColor: AppTheme.mint,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () async {
            final result = await context.push<TransactionMutationResult>(
              '/transaction-form',
            );
            if (result != null) {
              final months = <DateTime>{
                if (result.previousDate != null)
                  DateTime(result.previousDate!.year, result.previousDate!.month, 1),
                if (result.currentDate != null)
                  DateTime(result.currentDate!.year, result.currentDate!.month, 1),
              };
              for (final month in months) {
                ref.invalidate(calendarMonthProvider(month));
              }
              if (result.currentDate != null) {
                ref.read(calendarVisibleMonthProvider.notifier).setMonth(result.currentDate!);
              }
            }
          },
          child: const Icon(Icons.add, size: 34),
        ),
      ),
      bottomNavigationBar: MoniaryBottomNavBar(
        currentTab: currentTab,
        onTabSelected: (tab) {
          int index;
          switch (tab) {
            case MoniaryTab.calendar:
              index = 0;
              break;
            case MoniaryTab.groups:
              index = 1;
              break;
            case MoniaryTab.profile:
              index = 2;
              break;
            case MoniaryTab.stats:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.statsDevelopingMessage),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
