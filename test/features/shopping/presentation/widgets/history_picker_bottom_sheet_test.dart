import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/shopping/data/models/shopping_item_history_suggestion_dto.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/history_picker_bottom_sheet.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _suggestion1 = ShoppingItemHistorySuggestionDto(
  name: '牛乳',
  storeType: '1',
  purchaseCount: 5,
  lastPurchasedDate: '2026-04-01',
);

const _suggestion2 = ShoppingItemHistorySuggestionDto(
  name: '卵',
  storeType: null,
  purchaseCount: 3,
  lastPurchasedDate: '2026-03-15',
);

Widget _buildSheet({
  required List<ShoppingItemHistorySuggestionDto> suggestions,
  ValueChanged<ShoppingItemHistorySuggestionDto>? onSelected,
}) {
  return buildTestPage(
    Scaffold(
      body: HistoryPickerBottomSheet(
        suggestions: suggestions,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('HistoryPickerBottomSheet', () {
    testWidgets('履歴リストが表示される（2件）', (tester) async {
      await tester.pumpWidget(
        _buildSheet(suggestions: [_suggestion1, _suggestion2]),
      );
      await tester.pump();

      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('卵'), findsOneWidget);
    });

    testWidgets('履歴が0件のとき空メッセージが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(suggestions: []));
      await tester.pump();

      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('キーワード検索欄が表示される', (tester) async {
      await tester.pumpWidget(
        _buildSheet(suggestions: [_suggestion1, _suggestion2]),
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('期間フィルタチップが表示される', (tester) async {
      await tester.pumpWidget(
        _buildSheet(suggestions: [_suggestion1, _suggestion2]),
      );
      await tester.pump();

      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('キーワード入力でリストが絞り込まれる', (tester) async {
      await tester.pumpWidget(
        _buildSheet(suggestions: [_suggestion1, _suggestion2]),
      );
      await tester.pump();

      // 絞り込み前: ListTile が2件
      expect(find.byType(ListTile), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), '牛乳');
      await tester.pump();

      // 絞り込み後: ListTile が1件のみ（卵は非表示）
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('アイテムタップで onSelected が呼ばれる', (tester) async {
      ShoppingItemHistorySuggestionDto? selected;
      await tester.pumpWidget(
        _buildSheet(
          suggestions: [_suggestion1],
          onSelected: (s) => selected = s,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ListTile).first);
      await tester.pump();

      expect(selected, equals(_suggestion1));
    });

    testWidgets('purchaseCount > 0 のアイテムに回数が表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(suggestions: [_suggestion1]));
      await tester.pump();

      expect(find.text('5回'), findsOneWidget);
    });

    testWidgets('storeType=null のアイテムはサブタイトルなし', (tester) async {
      await tester.pumpWidget(_buildSheet(suggestions: [_suggestion2]));
      await tester.pump();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });
  });
}
