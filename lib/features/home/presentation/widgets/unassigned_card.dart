import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../home_state.dart';

class UnassignedCard extends StatelessWidget {
  const UnassignedCard({
    super.key,
    required this.summary,
    required this.onOpen,
  });

  final UnassignedSummary summary;
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
                Icon(
                  Icons.assignment_late_outlined,
                  color: colors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.homeUnassignedTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.homeUnassignedSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _UnassignedStatCard(
                    label: l10n.homeUnassignedTotal,
                    count: summary.totalCount,
                    subLabel: l10n.homeUnassignedTotalPeriod,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _UnassignedStatCard(
                    label: l10n.homeUnassignedUrgent,
                    count: summary.urgentCount,
                    subLabel: l10n.homeUnassignedUrgentDescription,
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeUnassignedNote,
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
                  child: Text(l10n.homeUnassignedOpenButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnassignedStatCard extends StatelessWidget {
  const _UnassignedStatCard({
    required this.label,
    required this.count,
    required this.subLabel,
    required this.colors,
  });

  final String label;
  final int count;
  final String subLabel;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        border: Border.all(color: colors.accentBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.textHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
