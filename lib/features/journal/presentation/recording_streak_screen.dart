import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/moniary_design.dart';
import '../application/journal_controller.dart';
import '../domain/journal_models.dart';

class RecordingStreakScreen extends ConsumerWidget {
  const RecordingStreakScreen({super.key});

  static const routePath = '/journal/streak';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(recordingStreakProvider);
    final colors = context.moniaryColors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colors.backgroundSoft,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.backgroundSoft,
        body: streakAsync.when(
          loading: () => const _StreakLoading(),
          error: (error, _) => _StreakError(
            onRetry: () => ref.invalidate(recordingStreakProvider),
          ),
          data: (streak) => _StreakContent(streak: streak),
        ),
      ),
    );
  }
}

class _StreakContent extends StatelessWidget {
  const _StreakContent({required this.streak});

  final RecordingStreak streak;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final startOfWeek = normalizedToday.subtract(
      Duration(days: normalizedToday.weekday - DateTime.monday),
    );
    final weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
    final latestRecordedDay = streak.recordedDays.isEmpty
        ? normalizedToday
        : streak.recordedDays.reduce((a, b) => a.isAfter(b) ? a : b);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(30, 18, 30, 48),
            children: [
              Row(
                children: [
                  _StreakBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.journalStreakBreadcrumb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.moniaryTypography.displaySmall.copyWith(
                        color: context.moniaryColors.textPrimary,
                        fontSize: 19,
                        height: 1.1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StreakBrandStrip(days: streak.currentDays),
              const SizedBox(height: 28),
              _StreakHero(streak: streak),
              const SizedBox(height: 24),
              _WeekStreakRail(
                days: weekDays,
                recordedDays: streak.recordedDays,
              ),
              const SizedBox(height: 30),
              _RecordCard(
                days: streak.longestDays,
                monthLabel: _monthLabel(context, latestRecordedDay),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    if (locale.startsWith('vi')) return 'Tháng ${date.month}, ${date.year}';
    return DateFormat.yMMMM(locale).format(date);
  }
}

class _StreakBackButton extends StatelessWidget {
  const _StreakBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Tooltip(
      message: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: colors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outline),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakBrandStrip extends StatelessWidget {
  const _StreakBrandStrip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outline.withValues(alpha: 0.82)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'MONIARY',
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: colors.textDim.withValues(alpha: 0.74),
                fontSize: 9,
                letterSpacing: 4,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    NumberFormat.decimalPattern(
                      Localizations.localeOf(context).toString(),
                    ).format(days),
                    style: context.moniaryTypography.metadataStrong.copyWith(
                      color: colors.primary,
                      fontSize: 12,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak});

  final RecordingStreak streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 92,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: colors.primary,
              size: 45,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          context.l10n.journalStreakDays(streak.currentDays),
          textAlign: TextAlign.center,
          style: context.moniaryTypography.displayLarge.copyWith(
            color: colors.textPrimary,
            fontSize: 32,
            height: 1.06,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 11),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            context.l10n.journalStreakBody(streak.currentDays),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.35,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekStreakRail extends StatelessWidget {
  const _WeekStreakRail({required this.days, required this.recordedDays});

  final List<DateTime> days;
  final Set<DateTime> recordedDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < days.length; index++) ...[
          Expanded(
            child: _WeekStreakTile(
              day: days[index],
              recorded: recordedDays.contains(days[index]),
            ),
          ),
          if (index != days.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _WeekStreakTile extends StatelessWidget {
  const _WeekStreakTile({required this.day, required this.recorded});

  final DateTime day;
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final fill = recorded
        ? colors.primary
        : colors.textPrimary.withValues(alpha: 0.08);
    final foreground = recorded
        ? AppTheme.surfaceRaised
        : colors.textPrimary.withValues(alpha: 0.14);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _weekdayLabel(context, day),
          style: context.moniaryTypography.metadataStrong.copyWith(
            color: colors.textDim.withValues(alpha: 0.72),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox.square(
            dimension: 32,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: foreground,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _weekdayLabel(BuildContext context, DateTime day) {
    final locale = Localizations.localeOf(context).toString();
    if (locale.startsWith('vi')) {
      return const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day.weekday - 1];
    }
    return DateFormat.E(locale).format(day).toUpperCase();
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.days, required this.monthLabel});

  final int days;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.outline.withValues(alpha: 0.78)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.journalStreakRecord.toUpperCase(),
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: colors.textDim.withValues(alpha: 0.72),
              fontSize: 9,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.journalStreakRecordDays(days),
            style: context.moniaryTypography.displaySmall.copyWith(
              color: colors.textPrimary,
              fontSize: 22,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monthLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary.withValues(alpha: 0.66),
              fontSize: 12,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakLoading extends StatelessWidget {
  const _StreakLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.moniaryColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StreakError extends StatelessWidget {
  const _StreakError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: MoniaryEditorialCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.errorGeneric,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
