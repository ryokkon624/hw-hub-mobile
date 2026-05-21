import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/favorite_picker_bottom_sheet.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _item1 = ShoppingItemDto(
  shoppingItemId: 1,
  householdId: 1,
  name: '牛乳',
  storeType: '1',
  status: '0',
  createdAt: '2026-01-01T00:00:00',
  hasImage: false,
);

const _item2 = ShoppingItemDto(
  shoppingItemId: 2,
  householdId: 1,
  name: '卵',
  storeType: null,
  status: '0',
  createdAt: '2026-01-02T00:00:00',
  hasImage: false,
);

Widget _buildSheet({
  required List<ShoppingItemDto> favorites,
  ValueChanged<ShoppingItemDto>? onSelected,
}) {
  return buildTestPage(
    Scaffold(
      body: FavoritePickerBottomSheet(
        favorites: favorites,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('FavoritePickerBottomSheet', () {
    testWidgets('お気に入りリストが表示される（2件）', (tester) async {
      await tester.pumpWidget(_buildSheet(favorites: [_item1, _item2]));
      await tester.pump();

      expect(find.text('牛乳'), findsOneWidget);
      expect(find.text('卵'), findsOneWidget);
    });

    testWidgets('お気に入りが0件のとき空メッセージが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(favorites: []));
      await tester.pump();

      // 空の場合はリストが表示されない
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('お気に入りアイテムにスター アイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(favorites: [_item1]));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('アイテムタップで onSelected が呼ばれる', (tester) async {
      ShoppingItemDto? selected;
      await tester.pumpWidget(
        _buildSheet(favorites: [_item1], onSelected: (item) => selected = item),
      );
      await tester.pump();

      await tester.tap(find.byType(ListTile).first);
      await tester.pump();

      expect(selected, equals(_item1));
    });

    testWidgets('storeType=1 のアイテムにサブタイトルが表示される', (tester) async {
      await tester.pumpWidget(_buildSheet(favorites: [_item1]));
      await tester.pump();

      // スーパーのラベルが表示される
      expect(find.byType(ListTile), findsOneWidget);
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNotNull);
    });

    testWidgets('storeType=null のアイテムはサブタイトルなし', (tester) async {
      await tester.pumpWidget(_buildSheet(favorites: [_item2]));
      await tester.pump();

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });
  });
}
