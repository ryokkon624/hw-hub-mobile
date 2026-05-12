import 'package:flutter/material.dart';
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
                    'これからの家事',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '未対応: ${tasks.length}件',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '今日以降に予定されている家事',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _FilterChip(
                    label: 'すべて',
                    selected: filter == MyTasksFilter.all,
                    onTap: () => ref
                        .read(myTasksNotifierProvider.notifier)
                        .setFilter(MyTasksFilter.all),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: '今日',
                    selected: filter == MyTasksFilter.today,
                    onTap: () => ref
                        .read(myTasksNotifierProvider.notifier)
                        .setFilter(MyTasksFilter.today),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: '1週間',
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
              _formatDateLabel(entry.key, entry.value.length),
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
                AppSnackBar.showSuccess('完了しました');
              },
              onSkip: () async {
                await ref
                    .read(myTasksNotifierProvider.notifier)
                    .skipTask(task.houseworkTaskId);
                AppSnackBar.showInfo('スキップしました');
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

  String _formatDateLabel(String dateStr, int count) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '$dateStr　$count件';
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final wd = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}（$wd）　$count件';
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
