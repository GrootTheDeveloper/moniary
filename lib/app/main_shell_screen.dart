import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_theme.dart';
import '../core/providers/camera_provider.dart';
import '../features/assistant/presentation/assistant_home_screen.dart';
import '../features/calendar/application/month/calendar_month_provider.dart';
import '../features/calendar/application/month/calendar_visible_month_provider.dart';
import '../features/transactions/domain/models/transaction_mutation_result.dart';
import '../features/transactions/presentation/form/create_transaction_sheet.dart';
import '../l10n/l10n_extension.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../shared/widgets/mascot_overlay.dart';
import '../core/widgets/widget_update_service.dart';

final _widgetBootstrapRunProvider = NotifierProvider<_BootstrapNotifier, bool>(_BootstrapNotifier.new);

class _BootstrapNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void markRun() => state = true;
}

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.moniaryColors;

    final bootstrapRun = ref.read(_widgetBootstrapRunProvider);
    if (!bootstrapRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(_widgetBootstrapRunProvider.notifier).markRun();
        ref.read(widgetUpdateServiceProvider).updateWidget().ignore();
      });
    }
    final currentTab = switch (navigationShell.currentIndex) {
      0 => MoniaryTab.calendar,
      1 => MoniaryTab.stats,
      2 => MoniaryTab.groups,
      3 => MoniaryTab.profile,
      _ => MoniaryTab.calendar,
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            right: 18,
            bottom: 18,
            child: _AssistantChatBubble(
              color: colors.button,
              foregroundColor: colors.surfaceRaised,
              onPressed: () => context.push(AssistantHomeScreen.routePath),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -10.0,
            height: 200.0,
            child: const MascotOverlay(),
          ),
        ],
      ),
      bottomNavigationBar: MoniaryBottomNavBar(
        currentTab: currentTab,
        onCameraPressed: () => _openCameraFlow(context, ref),
        onTabSelected: (tab) {
          final index = switch (tab) {
            MoniaryTab.calendar => 0,
            MoniaryTab.stats => 1,
            MoniaryTab.groups => 2,
            MoniaryTab.profile => 3,
          };
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  Future<void> _openCameraFlow(BuildContext context, WidgetRef ref) async {
    ref.read(cameraFailureReasonProvider.notifier).clear();

    final cameraResult = await context.push<TransactionMutationResult>(
      '/camera',
    );

    if (!context.mounted) return;

    if (cameraResult != null) {
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

    final failureReason = ref.read(cameraFailureReasonProvider);
    if (failureReason == null) return;

    final errorMessage = failureReason == CameraFailureReason.permissionDenied
        ? context.l10n.cameraFallbackPermissionDenied
        : context.l10n.cameraFallbackGenericError;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 4),
      ),
    );

    final createdAt = await showCreateTransactionSheet(context, ref);
    if (createdAt != null && context.mounted) {
      final month = DateTime(createdAt.year, createdAt.month, 1);
      ref.invalidate(calendarMonthProvider(month));
      ref.read(calendarVisibleMonthProvider.notifier).setMonth(month);
    }
  }
}

class _AssistantChatBubble extends StatelessWidget {
  const _AssistantChatBubble({
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
  });

  final Color color;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.assistantTitle,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: color.withValues(alpha: 0.22),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              Icons.chat_bubble_outline,
              color: foregroundColor,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}
