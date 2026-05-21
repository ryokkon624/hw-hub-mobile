import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_state.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/assign_filter_chips.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildChips({
  AssignFilter selected = AssignFilter.all,
  ValueChanged<AssignFilter>? onChanged,
}) => buildTestPage(
  Scaffold(
    body: AssignFilterChips(selected: selected, onChanged: onChanged ?? (_) {}),
  ),
);

void main() {
  group('AssignFilterChips', () {
    testWidgets('3つのフィルタチップが表示される', (tester) async {
      await tester.pumpWidget(_buildChips());
      await tester.pump();

      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('allフィルタチップをタップするとonChangedが呼ばれる', (tester) async {
      AssignFilter? changed;
      await tester.pumpWidget(
        _buildChips(
          selected: AssignFilter.unassignedOnly,
          onChanged: (f) => changed = f,
        ),
      );
      await tester.pump();

      // allチップをタップ（最初のChoiceChip）
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pump();

      expect(changed, AssignFilter.all);
    });

    testWidgets('unassignedOnlyフィルタチップをタップするとonChangedが呼ばれる', (tester) async {
      AssignFilter? changed;
      await tester.pumpWidget(
        _buildChips(selected: AssignFilter.all, onChanged: (f) => changed = f),
      );
      await tester.pump();

      // 2番目のChoiceChip（unassignedOnly）をタップ
      await tester.tap(find.byType(ChoiceChip).at(1));
      await tester.pump();

      expect(changed, AssignFilter.unassignedOnly);
    });

    testWidgets('meAndUnassignedフィルタチップをタップするとonChangedが呼ばれる', (tester) async {
      AssignFilter? changed;
      await tester.pumpWidget(
        _buildChips(selected: AssignFilter.all, onChanged: (f) => changed = f),
      );
      await tester.pump();

      // 3番目のChoiceChip（meAndUnassigned）をタップ
      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pump();

      expect(changed, AssignFilter.meAndUnassigned);
    });
  });
}
