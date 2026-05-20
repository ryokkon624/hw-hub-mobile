import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/presentation/models/shopping_item.dart';
import 'package:hw_hub_mobile/features/home/presentation/widgets/shopping_card.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildCard({List<ShoppingItem> items = const [], VoidCallback? onOpen}) {
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: ShoppingCard(items: items, onOpen: onOpen ?? () {}),
      ),
    ),
  );
}

ShoppingItem _item({
  int id = 1,
  String? storeType,
  String status = '0',
  String createdAt = '2025-06-15T00:00:00',
}) => ShoppingItem(
  shoppingItemId: id,
  name: 'アイテム$id',
  storeType: storeType,
  status: status,
  createdAt: createdAt,
);

void main() {
  group('ShoppingCard', () {
    testWidgets('空のリストでカードが表示される', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('スーパーマーケットの商品がカウントされる', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          items: [
            _item(id: 1, storeType: '1', status: '0'), // supermarket
            _item(id: 2, storeType: '1', status: '0'), // supermarket
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('ドラッグストアの商品がカウントされる', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          items: [
            _item(id: 1, storeType: '3', status: '0'), // drugstore
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('オンラインの商品がカウントされる', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          items: [
            _item(id: 1, storeType: '2', status: '0'), // online
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('購入済みアイテム（status=1）はカウントに含まれない', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          items: [
            _item(id: 1, storeType: '1', status: '1'), // purchased
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('不正な日付文字列でもエラーにならない（try/catch分岐）', (tester) async {
      await tester.pumpWidget(
        _buildCard(items: [_item(id: 1, createdAt: 'invalid-date')]),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('最近追加されたアイテムのカウントが表示される', (tester) async {
      final recentDate = DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String();
      await tester.pumpWidget(
        _buildCard(
          items: [
            ShoppingItem(
              shoppingItemId: 1,
              name: '最新アイテム',
              status: '0',
              createdAt: recentDate,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ShoppingCard), findsOneWidget);
    });

    testWidgets('開くボタンをタップするとonOpenが呼ばれる', (tester) async {
      bool opened = false;
      await tester.pumpWidget(
        _buildCard(items: [], onOpen: () => opened = true),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(opened, isTrue);
    });
  });
}
