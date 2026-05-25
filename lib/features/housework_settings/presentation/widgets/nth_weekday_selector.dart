import 'package:flutter/material.dart';
import '../../../../core/models/nth_week.dart';
import '../../../../l10n/app_localizations.dart';

/// 第n週+曜日選択ウィジェット。
class NthWeekdaySelector extends StatelessWidget {
  const NthWeekdaySelector({
    super.key,
    required this.nthWeek,
    required this.weekday,
    required this.onNthChanged,
    required this.onWeekdayChanged,
  });

  final int nthWeek;
  final int weekday;
  final void Function(int) onNthChanged;
  final void Function(int) onWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weekdayLabels = [
      l10n.houseworkWeekdaySun,
      l10n.houseworkWeekdayMon,
      l10n.houseworkWeekdayTue,
      l10n.houseworkWeekdayWed,
      l10n.houseworkWeekdayThu,
      l10n.houseworkWeekdayFri,
      l10n.houseworkWeekdaySat,
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const Key('nthWeekSelector'),
            initialValue: nthWeek,
            items: NthWeek.values
                .map(
                  (week) => DropdownMenuItem<int>(
                    value: int.parse(week.code),
                    child: Text(_nthWeekLabel(week, l10n)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onNthChanged(val);
            },
            decoration: InputDecoration(
              labelText: l10n.houseworkCreateNthWeekLabel,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: const Key('nthWeekdaySelector'),
            initialValue: weekday,
            items: List.generate(7, (i) => i)
                .map(
                  (i) => DropdownMenuItem<int>(
                    value: i,
                    child: Text(weekdayLabels[i]),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onWeekdayChanged(val);
            },
            decoration: InputDecoration(
              labelText: l10n.houseworkCreateNthWeekdayLabel,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// NthWeek enum を i18n 済みラベルに変換する。
  String _nthWeekLabel(NthWeek week, AppLocalizations l10n) {
    switch (week) {
      case NthWeek.firstWeek:
        return l10n.houseworkNthWeekFirst;
      case NthWeek.secondWeek:
        return l10n.houseworkNthWeekSecond;
      case NthWeek.thirdWeek:
        return l10n.houseworkNthWeekThird;
      case NthWeek.fourthWeek:
        return l10n.houseworkNthWeekFourth;
      case NthWeek.lastWeek:
        return l10n.houseworkNthWeekLast;
    }
  }
}
