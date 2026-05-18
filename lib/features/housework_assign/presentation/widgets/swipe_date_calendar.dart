import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// スワイプモードのカード上部に表示する月カレンダー（AC3）。
///
/// [targetDate] に対応する日をカレンダー上でハイライト表示する。
/// 読み取り専用（タップ・スワイプ無効）。
class SwipeDateCalendar extends StatelessWidget {
  const SwipeDateCalendar({super.key, required this.targetDate});

  /// ISO 8601 形式の日付文字列（例: "2026-05-20"）。null の場合は今日を表示。
  final String? targetDate;

  @override
  Widget build(BuildContext context) {
    final DateTime focusedDay = _parseDate(targetDate) ?? DateTime.now();
    final DateTime? selectedDay = _parseDate(targetDate);

    return TableCalendar(
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      focusedDay: focusedDay,
      selectedDayPredicate: selectedDay != null
          ? (day) => _isSameDay(day, selectedDay)
          : null,
      // 読み取り専用: onDaySelected を未指定
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
      ),
      availableGestures: AvailableGestures.none,
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
