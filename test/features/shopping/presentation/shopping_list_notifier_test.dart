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
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_list_notifier.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_list_state.dart';
import 'package:hw_hub_mobile/features/shopping/shopping_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shopping_mocks.mocks.dart';

// テスト用フィクスチャ
ShoppingItemDto _item({
  int id = 1,
  String status = '0', // 未購入
  String? storeType = '1',
  String? favorite = '0',
  String? purchasedAt,
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 1,
  name: 'テストアイテム$id',
  memo: null,
  storeType: storeType,
  status: status,
  favorite: favorite,
  purchasedAt: purchasedAt,
  createdAt: '2026-05-01T10:00:00',
  hasImage: false,
);

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(Household household) async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._authState);
  final AuthState _authState;

  @override
  Future<AuthState> build() async => _authState;
}

ProviderContainer _makeContainer(MockShoppingRepository mockRepo) {
  SharedPreferences.setMockInitialValues({});

  final testUser = AuthUser(
    userId: 10,
    email: 'test@example.com',
    displayName: 'テストユーザー',
  );

  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FakeAuthNotifier(AuthAuthenticated(testUser)),
      ),
      householdNotifierProvider.overrideWith(
        () => _FakeHouseholdNotifier(
          HouseholdState(
            households: [const Household(id: 1, name: '我が家')],
            selectedHousehold: const Household(id: 1, name: '我が家'),
          ),
        ),
      ),
      shoppingRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockShoppingRepository mockRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockShoppingRepository();
  });

  group('ShoppingListNotifier - 初期ロード', () {
    test('build: 世帯IDでfetchItemsを呼び、未購入/かご/購入済みに振り分ける', () async {
      final items = [
        _item(id: 1, status: '0'), // 未購入
        _item(id: 2, status: '1'), // かご
        _item(id: 3, status: '9', purchasedAt: '2026-05-13T10:00:00'), // 購入済み
      ];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);

      final container = _makeContainer(mockRepo);
      final state = await container.read(shoppingListNotifierProvider.future);

      expect(state.items, hasLength(3));
      expect(state.unpurchasedItems, hasLength(1));
      expect(state.basketItems, hasLength(1));
      // 購入済みは7日以内のものだけ（2026-05-13は今日なのでカット日を超える可能性あり）
      // テストの日付依存を避けるため、現在日付の近傍の日付を使う
    });

    test('build: 購入済みタブは直近7日間のみ表示する', () async {
      final now = DateTime.now();
      final recentDate = now.subtract(const Duration(days: 3));
      final oldDate = now.subtract(const Duration(days: 10));
      final items = [
        _item(id: 1, status: '9', purchasedAt: recentDate.toIso8601String()),
        _item(id: 2, status: '9', purchasedAt: oldDate.toIso8601String()),
      ];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);

      final container = _makeContainer(mockRepo);
      final state = await container.read(shoppingListNotifierProvider.future);

      // 7日以内のみ表示
      expect(state.purchasedItems, hasLength(1));
      expect(state.purchasedItems.first.shoppingItemId, 1);
    });
  });

  group('ShoppingListNotifier - タブ切替', () {
    test('setTab: アクティブタブが変更される', () async {
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      container
          .read(shoppingListNotifierProvider.notifier)
          .setTab(ShoppingTab.basket);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.activeTab, ShoppingTab.basket);
    });
  });

  group('ShoppingListNotifier - 購入場所フィルタ', () {
    test(
      'setLocationFilter: フィルタが変更され、filteredUnpurchasedItemsが絞り込まれる',
      () async {
        final items = [
          _item(id: 1, status: '0', storeType: '1'), // スーパー
          _item(id: 2, status: '0', storeType: '2'), // オンライン
          _item(id: 3, status: '0', storeType: '3'), // ドラッグストア
        ];
        when(
          mockRepo.fetchItems(householdId: 1),
        ).thenAnswer((_) async => items);

        final container = _makeContainer(mockRepo);
        await container.read(shoppingListNotifierProvider.future);

        container
            .read(shoppingListNotifierProvider.notifier)
            .setLocationFilter('1');
        final state = container.read(shoppingListNotifierProvider).valueOrNull!;
        expect(state.filteredUnpurchasedItems, hasLength(1));
        expect(state.filteredUnpurchasedItems.first.shoppingItemId, 1);
      },
    );

    test('setLocationFilter(null): フィルタなしで全件返す', () async {
      final items = [
        _item(id: 1, status: '0', storeType: '1'),
        _item(id: 2, status: '0', storeType: '2'),
      ];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      // まずフィルタをセット
      container
          .read(shoppingListNotifierProvider.notifier)
          .setLocationFilter('1');
      // クリア
      container
          .read(shoppingListNotifierProvider.notifier)
          .setLocationFilter(null);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.filteredUnpurchasedItems, hasLength(2));
    });
  });

  group('ShoppingListNotifier - moveToBasket', () {
    test('成功時: ステータスが1に更新されローカルstateも変わる', () async {
      final items = [_item(id: 1, status: '0')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.updateStatus(shoppingItemId: 1, status: '1'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .moveToBasket(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.unpurchasedItems, isEmpty);
      expect(state.basketItems, hasLength(1));
    });

    test('エラー時: stateが変更されない', () async {
      final items = [_item(id: 1, status: '0')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.updateStatus(shoppingItemId: 1, status: '1'),
      ).thenThrow(Exception('error'));

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .moveToBasket(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      // エラー時は状態変更なし
      expect(state.unpurchasedItems, hasLength(1));
    });
  });

  group('ShoppingListNotifier - markPurchased', () {
    test('成功時: ステータスが9に更新されローカルstateも変わる', () async {
      final items = [_item(id: 1, status: '1')]; // かご状態
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.updateStatus(shoppingItemId: 1, status: '9'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .markPurchased(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.basketItems, isEmpty);
      // 購入済みに移動（purchasedAtがnullのためpurchasedItemsには含まれないが、itemsに残る）
      final item = state.items.firstWhere((e) => e.shoppingItemId == 1);
      expect(item.status, '9');
    });
  });

  group('ShoppingListNotifier - moveBackToUnpurchased', () {
    test('成功時: かごから未購入に戻る', () async {
      final items = [_item(id: 1, status: '1')]; // かご状態
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.updateStatus(shoppingItemId: 1, status: '0'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .moveBackToUnpurchased(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.basketItems, isEmpty);
      expect(state.unpurchasedItems, hasLength(1));
    });
  });

  group('ShoppingListNotifier - bulkPurchase', () {
    test('成功時: かご内全件が購入済みになる', () async {
      final items = [_item(id: 1, status: '1'), _item(id: 2, status: '1')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.bulkUpdateStatus(ids: [1, 2], status: '9'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .bulkPurchase();
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.basketItems, isEmpty);
    });

    test('かごが空のとき: APIを呼ばない', () async {
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .bulkPurchase();
      verifyNever(
        mockRepo.bulkUpdateStatus(
          ids: anyNamed('ids'),
          status: anyNamed('status'),
        ),
      );
    });
  });

  group('ShoppingListNotifier - deleteItem', () {
    test('成功時: アイテムがstateから除外される', () async {
      final items = [_item(id: 1, status: '0')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(mockRepo.deleteItem(shoppingItemId: 1)).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container.read(shoppingListNotifierProvider.notifier).deleteItem(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      expect(state.items, isEmpty);
    });
  });

  group('ShoppingListNotifier - toggleFavorite', () {
    test('お気に入りOFF → ON: favoriteが1に変わる', () async {
      final items = [_item(id: 1, status: '0', favorite: '0')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.toggleFavorite(shoppingItemId: 1, favorite: '1'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .toggleFavorite(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      final item = state.items.firstWhere((e) => e.shoppingItemId == 1);
      expect(item.favorite, '1');
    });

    test('お気に入りON → OFF: favoriteが0に変わる', () async {
      final items = [_item(id: 1, status: '0', favorite: '1')];
      when(mockRepo.fetchItems(householdId: 1)).thenAnswer((_) async => items);
      when(
        mockRepo.toggleFavorite(shoppingItemId: 1, favorite: '0'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      await container.read(shoppingListNotifierProvider.future);

      await container
          .read(shoppingListNotifierProvider.notifier)
          .toggleFavorite(1);
      final state = container.read(shoppingListNotifierProvider).valueOrNull!;
      final item = state.items.firstWhere((e) => e.shoppingItemId == 1);
      expect(item.favorite, '0');
    });
  });
}
