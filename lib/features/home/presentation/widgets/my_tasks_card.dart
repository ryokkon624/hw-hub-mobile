import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../home_state.dart';

class MyTasksCard extends StatelessWidget {
  const MyTasksCard({super.key, required this.summary, required this.onOpen});

  final MyTasksSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Card(
      color: colors.surfaceCard,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.task_alt, color: colors.primary, size: 20),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.homeMyTasksTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: colors.textHeading,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.homeMyTasksSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.homeMyTasksToday,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.homeMyTasksCountFormat(summary.todayCount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      border: Border.all(color: colors.borderSubtle),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeMyTasksWeek,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeMyTasksCountFormat(summary.weekCount),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colors.textHeading,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.dangerSoft,
                      border: Border.all(color: colors.dangerBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeMyTasksOverdue,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textBody),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeMyTasksCountFormat(summary.overdueCount),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeMyTasksNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
                FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(l10n.homeMyTasksOpenButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
