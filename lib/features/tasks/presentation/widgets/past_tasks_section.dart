import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../data/my_tasks_repository.dart';
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
            color: colors.paletteRoseSoft,
            border: Border.all(color: colors.paletteRoseBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.paletteRoseText,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.myTasksPastSectionTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.paletteRoseText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.myTasksPastSectionSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.paletteRoseText),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () async {
                  final confirmed = await BulkCompleteDialog.show(context);
                  if (confirmed == true && context.mounted) {
                    await ref
                        .read(myTasksNotifierProvider.notifier)
                        .bulkCompletePastTasks();
                    AppSnackBar.showSuccess(l10n.myTasksBulkCompletedSnackBar);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.paletteRoseText,
                  side: BorderSide(color: colors.paletteRoseBorder),
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
