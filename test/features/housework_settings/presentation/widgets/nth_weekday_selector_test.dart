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

    testWidgets('nthWeekSelectorは第1週〜最終週の5項目を持つ（AC1）', (tester) async {
      await tester.pumpWidget(_buildSelector(nthWeek: 1));
      await tester.pump();

      // Dropdownを開いて項目を確認
      await tester.tap(find.byKey(const Key('nthWeekSelector')));
      await tester.pumpAndSettle();

      expect(find.text('第1週'), findsWidgets);
      expect(find.text('第2週'), findsOneWidget);
      expect(find.text('第3週'), findsOneWidget);
      expect(find.text('第4週'), findsOneWidget);
      // 最終週が表示されること（AC1の核心）
      expect(find.text('最終週'), findsOneWidget);
    });

    testWidgets('nthWeekdaySelectorは7曜日を持つ', (tester) async {
      await tester.pumpWidget(_buildSelector(weekday: 1));
      await tester.pump();

      await tester.tap(find.byKey(const Key('nthWeekdaySelector')));
      await tester.pumpAndSettle();

      // 7つの曜日DropdownMenuItemが存在する
      expect(find.byType(DropdownMenuItem<int>), findsAtLeastNWidgets(7));
    });

    testWidgets('nthWeekSelectorで値を変更するとonNthChangedが呼ばれる', (tester) async {
      int? changed;
      await tester.pumpWidget(
        _buildSelector(nthWeek: 1, onNthChanged: (v) => changed = v),
      );
      await tester.pump();

      // Dropdownを開く
      await tester.tap(find.byKey(const Key('nthWeekSelector')));
      await tester.pumpAndSettle();

      // 第3週を選択
      await tester.tap(find.text('第3週').last);
      await tester.pumpAndSettle();

      expect(changed, 3);
    });

    testWidgets('最終週（値=5）を選択するとonNthChangedが5で呼ばれる（AC1）', (tester) async {
      int? changed;
      await tester.pumpWidget(
        _buildSelector(nthWeek: 1, onNthChanged: (v) => changed = v),
      );
      await tester.pump();

      // Dropdownを開く
      await tester.tap(find.byKey(const Key('nthWeekSelector')));
      await tester.pumpAndSettle();

      // 最終週を選択
      await tester.tap(find.text('最終週').last);
      await tester.pumpAndSettle();

      expect(changed, 5);
    });

    testWidgets('nthWeekdaySelectorで値を変更するとonWeekdayChangedが呼ばれる', (
      tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _buildSelector(weekday: 1, onWeekdayChanged: (v) => changed = v),
      );
      await tester.pump();

      // Dropdownを開く
      await tester.tap(find.byKey(const Key('nthWeekdaySelector')));
      await tester.pumpAndSettle();

      // 土曜日（weekday=6）を選択
      await tester.tap(find.text('土').last);
      await tester.pumpAndSettle();

      expect(changed, 6);
    });
  });
}
