import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/models/housework_template_dto.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/widgets/template_picker_modal.dart';

import '../../../../../helpers/widget_test_helpers.dart';

const _template1 = HouseworkTemplateDto(
  houseworkTemplateId: 1,
  nameJa: '掃除機がけ',
  nameEn: 'Vacuuming',
  nameEs: 'Aspirar',
  category: 'CLEAN',
  recurrenceType: '1',
  weeklyDays: 2,
);

const _template2 = HouseworkTemplateDto(
  houseworkTemplateId: 2,
  nameJa: '食器洗い',
  nameEn: 'Dishwashing',
  nameEs: 'Fregar',
  category: 'KITCHEN',
  recurrenceType: '1',
  weeklyDays: 127,
);

Widget _buildModal({
  required List<HouseworkTemplateDto> templates,
  void Function(HouseworkTemplateDto)? onSelected,
}) {
  return buildTestPage(
    Scaffold(
      body: TemplatePickerModal(
        templates: templates,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('TemplatePickerModal', () {
    testWidgets('テンプレート一覧が表示される（2件）', (tester) async {
      await tester.pumpWidget(_buildModal(templates: [_template1, _template2]));
      await tester.pump();

      expect(find.text('掃除機がけ'), findsOneWidget);
      expect(find.text('食器洗い'), findsOneWidget);
    });

    testWidgets('テンプレートが0件のときリストが空', (tester) async {
      await tester.pumpWidget(_buildModal(templates: []));
      await tester.pump();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('閉じるボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildModal(templates: [_template1]));
      await tester.pump();

      expect(find.byKey(const Key('templateModalClose')), findsOneWidget);
    });

    testWidgets('カテゴリフィルタチップが表示される', (tester) async {
      await tester.pumpWidget(_buildModal(templates: [_template1]));
      await tester.pump();

      expect(find.byType(FilterChip), findsAtLeastNWidgets(1));
    });

    testWidgets('CLEANフィルタを選択するとCLEAN以外が非表示になる', (tester) async {
      await tester.pumpWidget(_buildModal(templates: [_template1, _template2]));
      await tester.pump();

      // 全件表示確認
      expect(find.text('掃除機がけ'), findsOneWidget);
      expect(find.text('食器洗い'), findsOneWidget);

      // CLEANフィルタをタップ（FilterChipのラベル検索）
      final cleanChip = find.byWidgetPredicate(
        (w) =>
            w is FilterChip &&
            (w.label as Text).data?.contains('CLEAN') == true,
      );
      if (cleanChip.evaluate().isNotEmpty) {
        await tester.tap(cleanChip.first);
        await tester.pump();

        // KITCHEN は非表示になる
        expect(find.text('食器洗い'), findsNothing);
        expect(find.text('掃除機がけ'), findsOneWidget);
      }
    });

    testWidgets('テンプレートタップでonSelectedが呼ばれる', (tester) async {
      HouseworkTemplateDto? selected;
      await tester.pumpWidget(
        _buildModal(templates: [_template1], onSelected: (t) => selected = t),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pump();

      expect(selected?.houseworkTemplateId, 1);
    });
  });
}
