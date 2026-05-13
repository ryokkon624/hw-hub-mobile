import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../data/models/housework_task_dto.dart';
import '../my_tasks_notifier.dart';
import 'bulk_complete_dialog.dart';
import 'swipeable_task_card.dart';

class PastTasksSection extends ConsumerWidget {
  const PastTasksSection({super.key, required this.tasks});

  final List<HouseworkTaskDto> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);
    final groups = _groupByDate(tasks);
    final now = DateTime.now();
    final todayStr = _dateStr(now);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.paletteRoseSoft,
              border: Border(
                bottom: BorderSide(color: colors.paletteRoseBorder),
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 左側: アイコン + タイトル + サブタイトル
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colors.paletteRoseText,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.myTasksPastSectionTitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.paletteRoseText,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.myTasksPastSectionSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.paletteRoseText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 右側: すべて完了にするボタン（小型 pill）
                ElevatedButton(
                  onPressed: () async {
                    final confirmed = await BulkCompleteDialog.show(context);
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(myTasksNotifierProvider.notifier)
                          .bulkCompletePastTasks();
                      AppSnackBar.showSuccess(
                        l10n.myTasksBulkCompletedSnackBar,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.myTasksPastSectionBulkCompleteButton),
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
                      color: colors.textMuted,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: SwipeableTaskCard(
                  task: task,
                  isPast: true,
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
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
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
