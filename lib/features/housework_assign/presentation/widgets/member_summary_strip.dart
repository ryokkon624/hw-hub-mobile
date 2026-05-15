import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../../data/housework_assign_repository.dart' show HouseholdMemberDto;

class MemberSummaryStrip extends StatelessWidget {
  const MemberSummaryStrip({
    super.key,
    required this.members,
    required this.memberTaskCounts,
    required this.unassignedCount,
    required this.currentUserId,
  });

  final List<HouseholdMemberDto> members;

  /// userId → 担当タスク件数の事前計算マップ（Notifier で集計済み）
  final Map<int, int> memberTaskCounts;

  /// 未割当タスク件数（Notifier で集計済み）
  final int unassignedCount;

  final int currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SummaryChip(
            label: l10n.houseworkAssignMemberSummaryUnassigned,
            count: unassignedCount,
            isHighlighted: false,
          ),
          ...members.map((m) {
            final count = memberTaskCounts[m.userId] ?? 0;
            return _SummaryChip(
              key: ValueKey(m.userId),
              label: m.displayName,
              count: count,
              isHighlighted: m.userId == currentUserId,
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    super.key,
    required this.label,
    required this.count,
    required this.isHighlighted,
  });

  final String label;
  final int count;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: isHighlighted
            ? Border.all(color: theme.colorScheme.primary)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
