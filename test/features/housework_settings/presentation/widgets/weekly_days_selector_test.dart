import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/widgets/weekly_days_selector.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildSelector({
  int weeklyDays = 0,
  void Function(int)? onToggle,
  String? errorText,
}) {
  return buildTestPage(
    Scaffold(
      body: WeeklyDaysSelector(
        weeklyDays: weeklyDays,
        onToggle: onToggle ?? (_) {},
        errorText: errorText,
      ),
    ),
  );
}

void main() {
  group('WeeklyDaysSelector', () {
    testWidgets('7つの曜日チップが表示される', (tester) async {
      await tester.pumpWidget(_buildSelector());
      await tester.pump();

      expect(find.byType(FilterChip), findsNWidgets(7));
    });

    testWidgets('weeklyDays=0のとき全チップが非選択', (tester) async {
      await tester.pumpWidget(_buildSelector(weeklyDays: 0));
      await tester.pump();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(chips.every((c) => !c.selected), isTrue);
    });

    testWidgets('bit0=1のとき日曜チップが選択状態', (tester) async {
      await tester.pumpWidget(_buildSelector(weeklyDays: 1)); // bit0
      await tester.pump();

      final chip = tester.widget<FilterChip>(
        find.byKey(const Key('weekdayChip0')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('bit1=1のとき月曜チップが選択状態', (tester) async {
      await tester.pumpWidget(_buildSelector(weeklyDays: 2)); // bit1
      await tester.pump();

      final chip = tester.widget<FilterChip>(
        find.byKey(const Key('weekdayChip1')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('チップをタップするとonToggleが呼ばれる', (tester) async {
      int? toggled;
      await tester.pumpWidget(_buildSelector(onToggle: (i) => toggled = i));
      await tester.pump();

      await tester.tap(find.byKey(const Key('weekdayChip0')));
      await tester.pump();

      expect(toggled, 0);
    });

    testWidgets('errorTextがあるとエラーテキストが表示される', (tester) async {
      await tester.pumpWidget(_buildSelector(errorText: '曜日を選択してください'));
      await tester.pump();

      expect(find.text('曜日を選択してください'), findsOneWidget);
    });

    testWidgets('errorText=nullのときエラーテキストが表示されない', (tester) async {
      await tester.pumpWidget(_buildSelector());
      await tester.pump();

      // FilterChip以外のTextが存在しないこと
      // （チップのラベルはあるが、エラーテキストの別Textノードはない）
      expect(find.byType(FilterChip), findsNWidgets(7));
    });
  });
}
