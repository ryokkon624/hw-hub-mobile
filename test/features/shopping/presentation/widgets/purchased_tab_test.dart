import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/purchased_tab.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/swipeable_shopping_card.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

/// テスト用アイテム
ShoppingItemDto _item({int id = 1, String name = 'テストアイテム'}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 1,
  name: name,
  memo: null,
  storeType: '1',
  status: '2',
  favorite: '0',
  purchasedAt: '2026-05-15T10:00:00',
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

/// テスト用の itemsByDate
Map<String, List<ShoppingItemDto>> _itemsByDate([ShoppingItemDto? item]) => {
  '2026-05-15': [item ?? _item()],
};

/// PurchasedTab をラップするヘルパー
Widget _buildApp({
  required Map<String, List<ShoppingItemDto>> itemsByDate,
  ValueChanged<int>? onCardTap,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: Scaffold(
        body: PurchasedTab(
          itemsByDate: itemsByDate,
          onCardTap: onCardTap ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('PurchasedTab - 左スワイプ対応（#91）', () {
    testWidgets('購入済みタブのカードがDismissibleを持つ（enableSwipe=true）', (tester) async {
      await tester.pumpWidget(_buildApp(itemsByDate: _itemsByDate()));
      await tester.pump();

      // SwipeableShoppingCard が存在する
      expect(find.byType(SwipeableShoppingCard), findsOneWidget);
      // enableSwipe=true なので Dismissible が存在する
      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('購入済みタブのDismissibleのdirectionがendToStartである', (tester) async {
      await tester.pumpWidget(_buildApp(itemsByDate: _itemsByDate()));
      await tester.pump();

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.endToStart);
    });

    testWidgets('購入済みタブで左スワイプするとSnackBarが表示される', (tester) async {
      await tester.pumpWidget(_buildApp(itemsByDate: _itemsByDate()));
      await tester.pump();

      // 左スワイプ（endToStart）
      await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // SnackBarが表示される
      expect(find.byType(SnackBar), findsOneWidget);
      // SnackBarにヒントメッセージが含まれる
      expect(find.text('ステータスを変更するには、編集画面で更新してください'), findsOneWidget);
    });

    testWidgets('購入済みタブで左スワイプ後もカードが残る（false を返してカードを元に戻す）', (tester) async {
      await tester.pumpWidget(_buildApp(itemsByDate: _itemsByDate()));
      await tester.pump();

      // 左スワイプ
      await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // カード（アイテム名）が残っている
      expect(find.text('テストアイテム'), findsOneWidget);
    });

    testWidgets('アイテムが0件のときDismissibleは存在しない', (tester) async {
      await tester.pumpWidget(_buildApp(itemsByDate: {}));
      await tester.pump();

      expect(find.byType(Dismissible), findsNothing);
    });
  });
}
