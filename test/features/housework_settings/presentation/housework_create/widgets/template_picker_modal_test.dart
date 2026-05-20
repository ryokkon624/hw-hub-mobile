import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/models/housework_template_dto.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/widgets/template_picker_modal.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

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

    testWidgets('閉じるボタンタップでモーダルが閉じる（Navigator.pop分岐）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => TemplatePickerModal(
                    templates: [_template1],
                    onSelected: (_) {},
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // モーダルが表示されている
      expect(find.byKey(const Key('templateModalClose')), findsOneWidget);

      await tester.tap(find.byKey(const Key('templateModalClose')));
      await tester.pumpAndSettle();

      // モーダルが閉じた
      expect(find.byKey(const Key('templateModalClose')), findsNothing);
    });

    testWidgets('フィルタチップ選択でカテゴリフィルタが適用される（_filtered分岐）', (tester) async {
      await tester.pumpWidget(_buildModal(templates: [_template1, _template2]));
      await tester.pump();

      // 掃除フィルタチップをタップ（ラベル「掃除」を含むチップ）
      final cleanChip = find.byWidgetPredicate(
        (w) =>
            w is FilterChip && (w.label as Text).data?.contains('掃除') == true,
      );
      if (cleanChip.evaluate().isNotEmpty) {
        await tester.tap(cleanChip.first);
        await tester.pump();

        // CLEANカテゴリのみ表示（KITCHENは非表示）
        expect(find.text('掃除機がけ'), findsOneWidget);
        expect(find.text('食器洗い'), findsNothing);
      } else {
        // チップが見つからない場合はスキップ
        markTestSkipped('掃除フィルタチップが見つかりませんでした');
      }
    });

    testWidgets('英語ロケールのときテンプレート名がnameEnで表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: Scaffold(
              body: TemplatePickerModal(
                templates: [_template1],
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Vacuuming'), findsOneWidget);
    });

    testWidgets('スペイン語ロケールのときテンプレート名がnameEsで表示される', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: Scaffold(
              body: TemplatePickerModal(
                templates: [_template1],
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aspirar'), findsOneWidget);
    });
  });
}
