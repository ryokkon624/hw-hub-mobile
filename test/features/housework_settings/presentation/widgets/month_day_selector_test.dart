import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/widgets/month_day_selector.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildSelector({int dayOfMonth = 1, void Function(int)? onChanged}) {
  return buildTestPage(
    Scaffold(
      body: MonthDaySelector(
        dayOfMonth: dayOfMonth,
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('MonthDaySelector', () {
    testWidgets('monthDaySelectorキーのDropdownが表示される', (tester) async {
      await tester.pumpWidget(_buildSelector());
      await tester.pump();

      expect(find.byKey(const Key('monthDaySelector')), findsOneWidget);
    });

    testWidgets('Dropdownが表示されている', (tester) async {
      await tester.pumpWidget(_buildSelector(dayOfMonth: 1));
      await tester.pump();

      // DropdownButtonFormFieldが描画されている
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('初期値15でDropdownが初期表示される', (tester) async {
      await tester.pumpWidget(_buildSelector(dayOfMonth: 15));
      await tester.pump();

      expect(find.byKey(const Key('monthDaySelector')), findsOneWidget);
    });
  });
}
