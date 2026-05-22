import '../home_state.dart';
import '../models/household_member.dart';

/// 棒グラフのツールチップに表示するテキスト行リストを構築する。
///
/// 戻り値: 各行のテキスト。メンバー行が先、未割当は末尾。
/// 全件0の場合は [noDataLabel] のみの1要素リストを返す。
List<String> buildTooltipLines(
  DailyOverview day,
  List<HouseholdMember> members, {
  required String unassignedLabel,
  String noDataLabel = '',
}) {
  final lines = <String>[];

  // メンバーごとの件数（0件はスキップ）
  for (final member in members) {
    final count = day.countsByAssignee[member.userId] ?? 0;
    if (count > 0) {
      final name = member.nickname ?? member.displayName;
      lines.add('$name: $count');
    }
  }

  // 未割当（0件はスキップ）
  final unassignedCount = day.countsByAssignee[null] ?? 0;
  if (unassignedCount > 0) {
    lines.add('$unassignedLabel: $unassignedCount');
  }

  // 全件0のとき
  if (lines.isEmpty && noDataLabel.isNotEmpty) {
    return [noDataLabel];
  }

  return lines;
}
