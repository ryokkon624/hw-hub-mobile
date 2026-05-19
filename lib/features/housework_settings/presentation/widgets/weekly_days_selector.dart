import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// 週次曜日選択ウィジェット（ビットマスク形式）。
/// bit0=日曜, bit1=月曜, ... bit6=土曜
class WeeklyDaysSelector extends StatelessWidget {
  const WeeklyDaysSelector({
    super.key,
    required this.weeklyDays,
    required this.onToggle,
    this.errorText,
  });

  final int weeklyDays;
  final void Function(int bit) onToggle;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.houseworkWeekdaySun,
      l10n.houseworkWeekdayMon,
      l10n.houseworkWeekdayTue,
      l10n.houseworkWeekdayWed,
      l10n.houseworkWeekdayThu,
      l10n.houseworkWeekdayFri,
      l10n.houseworkWeekdaySat,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: List.generate(7, (i) {
            final selected = weeklyDays & (1 << i) != 0;
            return FilterChip(
              key: Key('weekdayChip$i'),
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) => onToggle(i),
            );
          }),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
