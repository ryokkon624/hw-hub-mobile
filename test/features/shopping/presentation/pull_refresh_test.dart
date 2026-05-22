import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_item_list/shopping_list_page.dart';

import '../../../helpers/widget_test_helpers.dart';

ShoppingItemDto _item({
  int id = 1,
  String status = '0',
  String name = 'テストアイテム',
  String? storeType = '1',
  String? favorite = '0',
  String? purchasedAt,
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 1,
  name: name,
  memo: null,
  storeType: storeType,
  status: status,
  favorite: favorite,
  purchasedAt: purchasedAt,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthAuthenticated(
    AuthUser(userId: 1, email: 'test@example.com', displayName: 'テスト'),
  );
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  @override
  Future<HouseholdState> build() async => HouseholdState(
    households: [const Household(id: 1, name: '我が家')],
    selectedHousehold: const Household(id: 1, name: '我が家'),
  );

  @override
  Future<void> select(Household household) async {}
}

class _FakeShoppingListNotifier extends ShoppingListNotifier {
  _FakeShoppingListNotifier(this._items);
  final List<ShoppingItemDto> _items;

  @override
  Future<ShoppingListState> build() async {
    return ShoppingListState(items: List.unmodifiable(_items));
  }
}

List<Override> _buildOverrides(List<ShoppingItemDto> items) => [
  authNotifierProvider.overrideWith(() => _FakeAuthNotifier()),
  householdNotifierProvider.overrideWith(() => _FakeHouseholdNotifier()),
  shoppingListNotifierProvider.overrideWith(
    () => _FakeShoppingListNotifier(items),
  ),
];

void main() {
  group('プルリフレッシュ（#95）', () {
    testWidgets('未購入タブにRefreshIndicatorが存在する（#95）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides([_item()]),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 未購入タブが表示されている状態でRefreshIndicatorが存在することを確認
      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('かごタブにRefreshIndicatorが存在する（#95）', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides([_item(status: '1')]),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('購入済みタブにRefreshIndicatorが存在する（#95）', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        buildTestPage(
          const ShoppingListPage(),
          overrides: _buildOverrides([
            _item(status: '9', purchasedAt: now.toIso8601String()),
          ]),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('未購入タブが空のとき空メッセージが表示されかつRefreshIndicatorが存在する（#95）', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingListPage(), overrides: _buildOverrides([])),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('未購入のアイテムはありません'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('購入済みタブが空のとき空メッセージが表示されかつRefreshIndicatorが存在する（#95）', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(const ShoppingListPage(), overrides: _buildOverrides([])),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('購入済み'));
      await tester.pump();

      expect(find.text('購入済みアイテムはありません'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsAtLeastNWidgets(1));
    });
  });
}
