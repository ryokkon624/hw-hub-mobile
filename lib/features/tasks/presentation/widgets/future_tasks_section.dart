import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../data/my_tasks_repository.dart';
import '../my_tasks_notifier.dart';
import '../my_tasks_state.dart';
import 'swipeable_task_card.dart';

class FutureTasksSection extends ConsumerWidget {
  const FutureTasksSection({
    super.key,
    required this.tasks,
    required this.filter,
  });

  final List<HouseworkTaskDto> tasks;
  final MyTasksFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);
    final groups = _groupByDate(tasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.myTasksFutureSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.myTasksFutureSectionPendingCount(tasks.length),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.myTasksFutureSectionSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _FilterChip(
                    label: l10n.myTasksFilterAll,
                    selected: filter == MyTasksFilter.all,
                    onTap: () => ref
                        .read(myTasksNotifierProvider.notifier)
                        .setFilter(MyTasksFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: l10n.myTasksFilterToday,
                    selected: filter == MyTasksFilter.today,
                    onTap: () => ref
                        .read(myTasksNotifierProvider.notifier)
                        .setFilter(MyTasksFilter.today),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: l10n.myTasksFilterWeek,
                    selected: filter == MyTasksFilter.week,
                    onTap: () => ref
                        .read(myTasksNotifierProvider.notifier)
                        .setFilter(MyTasksFilter.week),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              _formatDateLabel(l10n, entry.key, entry.value.length),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.textMuted),
            ),
          ),
          for (final task in entry.value)
            SwipeableTaskCard(
              task: task,
              onComplete: () async {
                await ref
                    .read(myTasksNotifierProvider.notifier)
                    .completeTask(task.houseworkTaskId);
                AppSnackBar.showSuccess(l10n.myTasksCompletedSnackBar);
              },
              onSkip: () async {
                await ref
                    .read(myTasksNotifierProvider.notifier)
                    .skipTask(task.houseworkTaskId);
                AppSnackBar.showInfo(l10n.myTasksSkippedSnackBar);
              },
            ),
        ],
      ],
    );
  }

  Map<String, List<HouseworkTaskDto>> _groupByDate(
    List<HouseworkTaskDto> tasks,
  ) {
    final map = <String, List<HouseworkTaskDto>>{};
    for (final task in tasks) {
      map.putIfAbsent(task.targetDate, () => []).add(task);
    }
    return map;
  }

  String _formatDateLabel(AppLocalizations l10n, String dateStr, int count) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return l10n.myTasksDateLabelFallback(dateStr, count);
    final weekdays = [
      l10n.myTasksWeekdayMon,
      l10n.myTasksWeekdayTue,
      l10n.myTasksWeekdayWed,
      l10n.myTasksWeekdayThu,
      l10n.myTasksWeekdayFri,
      l10n.myTasksWeekdaySat,
      l10n.myTasksWeekdaySun,
    ];
    final wd = weekdays[date.weekday - 1];
    return l10n.myTasksDateLabel(date.month, date.day, wd, count);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? colors.onPrimary : colors.textBody,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
