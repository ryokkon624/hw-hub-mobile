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
              children: [
                Icon(Icons.task_alt, color: colors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.homeMyTasksTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.homeMyTasksSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: l10n.homeMyTasksToday,
                    count: summary.todayCount,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: l10n.homeMyTasksWeek,
                    count: summary.weekCount,
                    color: colors.textBody,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: l10n.homeMyTasksOverdue,
                    count: summary.overdueCount,
                    color: summary.overdueCount > 0
                        ? colors.danger
                        : colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primaryBorder),
                ),
                child: Text(l10n.homeMyTasksOpenButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
