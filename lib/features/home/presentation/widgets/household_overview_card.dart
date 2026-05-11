import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/household_member_dto.dart';
import '../home_state.dart';

/// メンバーカラーパレット（6色 + 未割当グレー）
const _memberColors = [
  Color(0xFF059669), // emerald-600
  Color(0xFF2563EB), // blue-600
  Color(0xFFD97706), // amber-600
  Color(0xFF7C3AED), // violet-600
  Color(0xFFDB2777), // pink-600
  Color(0xFF0891B2), // cyan-600
];
const _unassignedColor = Color(0xFF94A3B8); // slate-400

class HouseholdOverviewCard extends StatelessWidget {
  const HouseholdOverviewCard({
    super.key,
    required this.overview,
    required this.members,
  });

  final List<DailyOverview> overview;
  final List<HouseholdMemberDto> members;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    // メンバーIDとカラーのマッピング
    final memberColorMap = <int, Color>{};
    for (var i = 0; i < members.length; i++) {
      memberColorMap[members[i].userId] =
          _memberColors[i % _memberColors.length];
    }

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
                Icon(Icons.bar_chart, color: colors.primary, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.homeOverviewTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textHeading,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.homeOverviewSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: _OverviewChart(
                overview: overview,
                memberColorMap: memberColorMap,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 凡例
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ...members.map(
                  (m) => _LegendDot(
                    color: memberColorMap[m.userId] ?? _unassignedColor,
                    label: m.nickname ?? m.displayName,
                  ),
                ),
                _LegendDot(
                  color: _unassignedColor,
                  label: l10n.homeOverviewUnassigned,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewChart extends StatelessWidget {
  const _OverviewChart({required this.overview, required this.memberColorMap});

  final List<DailyOverview> overview;
  final Map<int, Color> memberColorMap;

  @override
  Widget build(BuildContext context) {
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < overview.length; i++) {
      final day = overview[i];
      final rodStackItems = <BarChartRodStackItem>[];
      double fromY = 0;

      // 未割当
      final unassignedCount = (day.countsByAssignee[null] ?? 0).toDouble();
      if (unassignedCount > 0) {
        rodStackItems.add(
          BarChartRodStackItem(
            fromY,
            fromY + unassignedCount,
            _unassignedColor,
          ),
        );
        fromY += unassignedCount;
      }

      // メンバーごと
      day.countsByAssignee.forEach((userId, count) {
        if (userId == null) return;
        final color = memberColorMap[userId] ?? _unassignedColor;
        final c = count.toDouble();
        if (c > 0) {
          rodStackItems.add(BarChartRodStackItem(fromY, fromY + c, color));
          fromY += c;
        }
      });

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: fromY > 0 ? fromY : 0.001, // 0のとき最小バーを表示
              rodStackItems: rodStackItems.isNotEmpty
                  ? rodStackItems
                  : [
                      BarChartRodStackItem(
                        0,
                        0.001,
                        _unassignedColor.withValues(alpha: 0.2),
                      ),
                    ],
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= overview.length) {
                  return const SizedBox.shrink();
                }
                // 今日のみラベルを強調、他は3日ごとに表示
                final date = overview[idx].date;
                final isToday = idx == 6; // 中央（7番目）が今日
                if (!isToday && idx % 3 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? const Color(0xFF059669)
                          : const Color(0xFF64748B),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        groupsSpace: 4,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}
