import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/widgets/nth_weekday_selector.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildSelector({
  int nthWeek = 1,
  int weekday = 1,
  void Function(int)? onNthChanged,
  void Function(int)? onWeekdayChanged,
}) {
  return buildTestPage(
    Scaffold(
      body: NthWeekdaySelector(
        nthWeek: nthWeek,
        weekday: weekday,
        onNthChanged: onNthChanged ?? (_) {},
        onWeekdayChanged: onWeekdayChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('NthWeekdaySelector', () {
    testWidgets('nthWeekSelector と nthWeekdaySelector が表示される', (tester) async {
      await tester.pumpWidget(_buildSelector());
      await tester.pump();

      expect(find.byKey(const Key('nthWeekSelector')), findsOneWidget);
      expect(find.byKey(const Key('nthWeekdaySelector')), findsOneWidget);
    });

    testWidgets('nthWeekSelectorは第1〜第5の5項目を持つ', (tester) async {
      await tester.pumpWidget(_buildSelector(nthWeek: 1));
      await tester.pump();

      // Dropdownを開いて項目数を確認
      await tester.tap(find.byKey(const Key('nthWeekSelector')));
      await tester.pumpAndSettle();

      expect(find.text('第1'), findsWidgets);
      expect(find.text('第5'), findsOneWidget);
    });

    testWidgets('nthWeekdaySelectorは7曜日を持つ', (tester) async {
      await tester.pumpWidget(_buildSelector(weekday: 1));
      await tester.pump();

      await tester.tap(find.byKey(const Key('nthWeekdaySelector')));
      await tester.pumpAndSettle();

      // 7つの曜日DropdownMenuItemが存在する
      expect(find.byType(DropdownMenuItem<int>), findsAtLeastNWidgets(7));
    });
  });
}
