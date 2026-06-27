import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../core/providers/camera_provider.dart';
import '../features/calendar/application/month/calendar_month_provider.dart';
import '../features/calendar/application/month/calendar_visible_month_provider.dart';
import '../features/transactions/domain/models/transaction_mutation_result.dart';
import '../features/transactions/presentation/form/create_transaction_sheet.dart';
import '../l10n/l10n_extension.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MoniaryTab currentTab;
    switch (navigationShell.currentIndex) {
      case 0:
        currentTab = MoniaryTab.calendar;
        break;
      case 1:
        currentTab = MoniaryTab.stats;
        break;
      case 2:
        currentTab = MoniaryTab.groups;
        break;
      case 3:
        currentTab = MoniaryTab.profile;
        break;
      default:
        currentTab = MoniaryTab.calendar;
    }

    final showFab =
        currentTab == MoniaryTab.calendar || currentTab == MoniaryTab.stats;

    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showFab
          ? SizedBox(
              width: 66,
              height: 66,
              child: FloatingActionButton(
                backgroundColor: AppTheme.mint,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                onPressed: () async {
                  // Reset any previous failure signal before opening camera.
                  ref.read(cameraFailureReasonProvider.notifier).clear();

                  // Primary path: open camera screen.
                  final cameraResult =
                      await context.push<TransactionMutationResult>('/camera');

                  if (!context.mounted) return;

                  if (cameraResult != null) {
                    // ✅ Camera flow succeeded — refresh calendar.
                    final months = <DateTime>{
                      if (cameraResult.previousDate != null)
                        DateTime(
                          cameraResult.previousDate!.year,
                          cameraResult.previousDate!.month,
                          1,
                        ),
                      if (cameraResult.currentDate != null)
                        DateTime(
                          cameraResult.currentDate!.year,
                          cameraResult.currentDate!.month,
                          1,
                        ),
                    };
                    for (final month in months) {
                      ref.invalidate(calendarMonthProvider(month));
                    }
                    if (cameraResult.currentDate != null) {
                      ref
                          .read(calendarVisibleMonthProvider.notifier)
                          .setMonth(cameraResult.currentDate!);
                    }
                    return;
                  }

                  // Check if camera closed due to failure (not user pressing ×).
                  final failureReason = ref.read(cameraFailureReasonProvider);
                  if (failureReason == null) return; // User cancelled — do nothing.

                  // ⚠️ Camera failed — show user-friendly SnackBar then open manual sheet.
                  final errorMessage =
                      failureReason == CameraFailureReason.permissionDenied
                          ? context.l10n.cameraFallbackPermissionDenied
                          : context.l10n.cameraFallbackGenericError;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      duration: const Duration(seconds: 4),
                    ),
                  );

                  // Fallback path: manual entry sheet opens immediately.
                  final createdAt =
                      await showCreateTransactionSheet(context, ref);
                  if (createdAt != null && context.mounted) {
                    final month =
                        DateTime(createdAt.year, createdAt.month, 1);
                    ref.invalidate(calendarMonthProvider(month));
                    ref
                        .read(calendarVisibleMonthProvider.notifier)
                        .setMonth(month);
                  }
                },
                child: const Icon(Icons.add, size: 34),
              ),
            )
          : null,
      bottomNavigationBar: MoniaryBottomNavBar(
        currentTab: currentTab,
        onTabSelected: (tab) {
          int index;
          switch (tab) {
            case MoniaryTab.calendar:
              index = 0;
              break;
            case MoniaryTab.stats:
              index = 1;
              break;
            case MoniaryTab.groups:
              index = 2;
              break;
            case MoniaryTab.profile:
              index = 3;
              break;
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
