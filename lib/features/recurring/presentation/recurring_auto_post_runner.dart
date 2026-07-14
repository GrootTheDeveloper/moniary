import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/month/calendar_month_provider.dart';
import '../../statistics/presentation/statistics_view.dart';
import '../../transactions/application/queries/transaction_queries.dart';
import '../application/recurring_controller.dart';
import '../application/recurring_materialization_service.dart';

/// Invisible widget that runs the recurring auto-post catch-up pass once when
/// mounted, then refreshes any view that could show the new transactions.
/// Mounted in the authenticated shell so it fires on every app launch.
class RecurringAutoPostRunner extends ConsumerStatefulWidget {
  const RecurringAutoPostRunner({super.key});

  @override
  ConsumerState<RecurringAutoPostRunner> createState() =>
      _RecurringAutoPostRunnerState();
}

class _RecurringAutoPostRunnerState
    extends ConsumerState<RecurringAutoPostRunner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final posted = await ref
        .read(recurringMaterializationServiceProvider)
        .run();
    if (posted == 0 || !mounted) return;
    ref.invalidate(recurringControllerProvider);
    ref.invalidate(calendarMonthProvider);
    ref.invalidate(statisticsMonthProvider);
    ref.invalidate(transactionSearchProvider);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
