import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_detail/shopping_item_detail_state.dart';

ShoppingItemDto _makeItem({required String status}) => ShoppingItemDto(
  shoppingItemId: 1,
  householdId: 100,
  name: 'テストアイテム',
  memo: null,
  storeType: '1',
  status: status,
  favorite: '0',
  purchasedAt: null,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

void main() {
  group('ShoppingItemDetailState - isNotPurchased', () {
    test('未購入（status=0）: true を返す', () {
      final state = ShoppingItemDetailState(item: _makeItem(status: '0'));
      // #94: notPurchased のみ true
      expect(state.isNotPurchased, isTrue);
    });

    test('かご（status=1）: false を返す（#94 バグ修正確認）', () {
      final state = ShoppingItemDetailState(item: _makeItem(status: '1'));
      // #94: inBasket は削除ボタンを表示しない
      expect(state.isNotPurchased, isFalse);
    });

    test('購入済み（status=9）: false を返す', () {
      final state = ShoppingItemDetailState(item: _makeItem(status: '9'));
      expect(state.isNotPurchased, isFalse);
    });

    test('item が null: false を返す', () {
      const state = ShoppingItemDetailState();
      expect(state.isNotPurchased, isFalse);
    });
  });
}
