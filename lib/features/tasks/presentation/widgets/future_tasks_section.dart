import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
    final now = DateTime.now();
    final todayStr = _dateStr(now);
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側: タイトル + サブタイトル
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myTasksFutureSectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.myTasksFutureSectionSubtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 右側: フィルタ（セグメントコントロール風）+ 件数
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // セグメントコントロール（選択中=白背景+影、非選択=透明）
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SegmentButton(
                          label: l10n.myTasksFilterAll,
                          selected: filter == MyTasksFilter.all,
                          onTap: () => ref
                              .read(myTasksNotifierProvider.notifier)
                              .setFilter(MyTasksFilter.all),
                        ),
                        _SegmentButton(
                          label: l10n.myTasksFilterToday,
                          selected: filter == MyTasksFilter.today,
                          onTap: () => ref
                              .read(myTasksNotifierProvider.notifier)
                              .setFilter(MyTasksFilter.today),
                        ),
                        _SegmentButton(
                          label: l10n.myTasksFilterWeek,
                          selected: filter == MyTasksFilter.week,
                          onTap: () => ref
                              .read(myTasksNotifierProvider.notifier)
                              .setFilter(MyTasksFilter.week),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 件数（フィルタの下に小さく表示）
                  Text(
                    l10n.myTasksFutureSectionPendingCount(tasks.length),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
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
            child: Row(
              children: [
                Text(
                  _formatDateLabel(l10n, entry.key, todayStr),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: entry.key == todayStr
                        ? colors.primary
                        : colors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.myTasksGroupCount(entry.value.length),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          for (final task in entry.value)
            SwipeableTaskCard(
              task: task,
              isToday: task.targetDate == todayStr,
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

  String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDateLabel(
    AppLocalizations l10n,
    String dateStr,
    String todayStr,
  ) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;

    if (dateStr == todayStr) return l10n.myTasksDateToday;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = _dateStr(tomorrow);
    if (dateStr == tomorrowStr) return l10n.myTasksDateTomorrow;

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
    return l10n.myTasksDateLabelShort(date.month, date.day, wd);
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceCard : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? colors.textHeading : colors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
