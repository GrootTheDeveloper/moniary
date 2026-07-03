import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../application/journal_controller.dart';

class RecordingStreakScreen extends ConsumerWidget {
  const RecordingStreakScreen({super.key});

  static const routePath = '/journal/streak';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(recordingStreakProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.journalStreakTitle)),
      body: streakAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(context.l10n.errorGeneric)),
        data: (streak) {
          final today = DateTime.now();
          final days = List.generate(7, (index) {
            final day = today.subtract(Duration(days: 6 - index));
            return DateTime(day.year, day.month, day.day);
          });
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.terracotta.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_outlined,
                    color: AppTheme.terracotta,
                    size: 46,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.journalStreakDays(streak.currentDays),
                textAlign: TextAlign.center,
                style: context.moniaryTypography.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.journalStreakBody(streak.currentDays),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final day in days)
                    Column(
                      children: [
                        Text(
                          DateFormat.E(
                            Localizations.localeOf(context).toString(),
                          ).format(day).toUpperCase(),
                          style: context.moniaryTypography.metadata,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: streak.recordedDays.contains(day)
                                ? AppTheme.terracotta
                                : context.moniaryColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: streak.recordedDays.contains(day)
                                  ? AppTheme.terracotta
                                  : context.moniaryColors.outline,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: context.moniaryTypography.metadataStrong
                                .copyWith(
                                  color: streak.recordedDays.contains(day)
                                      ? Colors.white
                                      : context.moniaryColors.textDim,
                                ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),
              MoniaryEditorialCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AppTheme.sand,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.l10n.journalStreakRecord.toUpperCase(),
                        style: context.moniaryTypography.metadataStrong,
                      ),
                    ),
                    Text(
                      context.l10n.journalStreakRecordDays(streak.longestDays),
                      style: context.moniaryTypography.displaySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
