import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/providers.dart';
import '../data/shopping_repository.dart';
import '../shopping_providers.dart';
import 'shopping_list_state.dart';

class ShoppingListNotifier extends AutoDisposeAsyncNotifier<ShoppingListState> {
  @override
  Future<ShoppingListState> build() async {
    final householdState = await ref.watch(householdNotifierProvider.future);
    final selectedHousehold = householdState.selectedHousehold;

    if (selectedHousehold == null) {
      return const ShoppingListState();
    }

    return _load(selectedHousehold.id);
  }

  Future<ShoppingListState> _load(int householdId) async {
    final repo = ref.read(shoppingRepositoryProvider);
    final items = await repo.fetchItems(householdId: householdId);
    final currentFilter = state.valueOrNull?.locationFilter;
    final currentTab = state.valueOrNull?.activeTab ?? ShoppingTab.unpurchased;

    return ShoppingListState(
      items: List.unmodifiable(items),
      locationFilter: currentFilter,
      activeTab: currentTab,
    );
  }

  void setTab(ShoppingTab tab) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(activeTab: tab));
  }

  void setLocationFilter(String? filter) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(locationFilter: filter));
  }

  Future<void> moveToBasket(int shoppingItemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.updateStatus(shoppingItemId: shoppingItemId, status: '1');
      final updatedItems = current.items.map((item) {
        if (item.shoppingItemId == shoppingItemId) {
          // かごに入れる際は purchasedAt をクリア
          return _copyItemWithStatus(item, '1', purchasedAt: null);
        }
        return item;
      }).toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> markPurchased(int shoppingItemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.updateStatus(shoppingItemId: shoppingItemId, status: '9');
      // #88: purchasedAt を現在時刻にセットすることで purchasedItems getter が即時反映される
      final now = DateTime.now().toIso8601String();
      final updatedItems = current.items.map((item) {
        if (item.shoppingItemId == shoppingItemId) {
          return _copyItemWithStatus(item, '9', purchasedAt: now);
        }
        return item;
      }).toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> moveBackToUnpurchased(int shoppingItemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.updateStatus(shoppingItemId: shoppingItemId, status: '0');
      final updatedItems = current.items.map((item) {
        if (item.shoppingItemId == shoppingItemId) {
          // 未購入に戻す際は purchasedAt をクリア（purchasedItems から外れる）
          return _copyItemWithStatus(item, '0', purchasedAt: null);
        }
        return item;
      }).toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> bulkPurchase() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final basketItems = current.basketItems;
    if (basketItems.isEmpty) return;

    final ids = basketItems.map((e) => e.shoppingItemId).toList();
    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.bulkUpdateStatus(ids: ids, status: '9');
      // #88: purchasedAt を現在時刻にセットすることで purchasedItems getter が即時反映される
      final now = DateTime.now().toIso8601String();
      final updatedItems = current.items.map((item) {
        if (ids.contains(item.shoppingItemId)) {
          return _copyItemWithStatus(item, '9', purchasedAt: now);
        }
        return item;
      }).toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteItem(int shoppingItemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.deleteItem(shoppingItemId: shoppingItemId);
      final updatedItems = current.items
          .where((item) => item.shoppingItemId != shoppingItemId)
          .toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> toggleFavorite(int shoppingItemId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final item = current.items
        .where((e) => e.shoppingItemId == shoppingItemId)
        .firstOrNull;
    if (item == null) return;

    // 現在の favorite を反転
    final currentFavorite = item.favorite ?? '0';
    final newFavorite = currentFavorite == '1' ? '0' : '1';

    final repo = ref.read(shoppingRepositoryProvider);
    try {
      await repo.toggleFavorite(
        shoppingItemId: shoppingItemId,
        favorite: newFavorite,
      );
      final updatedItems = current.items.map((e) {
        if (e.shoppingItemId == shoppingItemId) {
          return _copyItemWithFavorite(e, newFavorite);
        }
        return e;
      }).toList();
      state = AsyncData(
        current.copyWith(items: List.unmodifiable(updatedItems)),
      );
    } catch (_) {
      rethrow;
    }
  }

  /// ShoppingItemDto は immutable で copyWith がないため、新しいインスタンスを作成する
  /// [purchasedAt]: 購入済みに変更する際は現在時刻を渡す。未購入/かごに戻す際は null を渡す
  ShoppingItemDto _copyItemWithStatus(
    ShoppingItemDto item,
    String status, {
    required String? purchasedAt,
  }) {
    return ShoppingItemDto(
      shoppingItemId: item.shoppingItemId,
      householdId: item.householdId,
      name: item.name,
      memo: item.memo,
      storeType: item.storeType,
      status: status,
      favorite: item.favorite,
      purchasedAt: purchasedAt,
      createdAt: item.createdAt,
      hasImage: item.hasImage,
    );
  }

  ShoppingItemDto _copyItemWithFavorite(ShoppingItemDto item, String favorite) {
    return ShoppingItemDto(
      shoppingItemId: item.shoppingItemId,
      householdId: item.householdId,
      name: item.name,
      memo: item.memo,
      storeType: item.storeType,
      status: item.status,
      favorite: favorite,
      purchasedAt: item.purchasedAt,
      createdAt: item.createdAt,
      hasImage: item.hasImage,
    );
  }
}

final shoppingListNotifierProvider =
    AsyncNotifierProvider.autoDispose<ShoppingListNotifier, ShoppingListState>(
      ShoppingListNotifier.new,
    );
