import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// 月次・日付選択ウィジェット。（1〜30, 31=月末）
class MonthDaySelector extends StatelessWidget {
  const MonthDaySelector({
    super.key,
    required this.dayOfMonth,
    required this.onChanged,
  });

  final int dayOfMonth;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      ...List.generate(
        30,
        (i) => i + 1,
      ).map((day) => DropdownMenuItem<int>(value: day, child: Text('$day'))),
      DropdownMenuItem<int>(value: 31, child: Text(l10n.houseworkMonthEndDay)),
    ];

    return DropdownButtonFormField<int>(
      key: const Key('monthDaySelector'),
      initialValue: dayOfMonth,
      items: items,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      decoration: InputDecoration(
        labelText: l10n.houseworkCreateMonthlyDayLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
