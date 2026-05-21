import '../../data/shopping_repository.dart';

enum ShoppingTab { unpurchased, basket, purchased }

class ShoppingListState {
  const ShoppingListState({
    this.items = const [],
    this.locationFilter,
    this.activeTab = ShoppingTab.unpurchased,
    this.errorMessage,
  });

  final List<ShoppingItemDto> items;

  /// null = すべて、PurchaseLocationType.code の値（'1'/'2'/'3'）
  final String? locationFilter;

  final ShoppingTab activeTab;

  /// 操作エラー時のメッセージ（i18nキー名 or AppExceptionのメッセージ）
  final String? errorMessage;

  // ─── 派生 getter ────────────────────────────────────────────────
  List<ShoppingItemDto> get unpurchasedItems =>
      items.where((e) => e.status == '0').toList();

  List<ShoppingItemDto> get basketItems =>
      items.where((e) => e.status == '1').toList();

  /// 直近7日間の購入済みアイテム（purchasedAt が null のものは除外）
  List<ShoppingItemDto> get purchasedItems {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return items.where((e) {
      if (e.status != '9') return false;
      final at = e.purchasedAt;
      if (at == null) return false;
      final dt = DateTime.tryParse(at);
      if (dt == null) return false;
      return dt.isAfter(cutoff);
    }).toList();
  }

  /// 購入場所フィルタを適用した未購入アイテム
  List<ShoppingItemDto> get filteredUnpurchasedItems {
    final base = unpurchasedItems;
    final filter = locationFilter;
    if (filter == null) return base;
    return base.where((e) => e.storeType == filter).toList();
  }

  /// 購入済みアイテムを日付グループ（purchasedAt の日付）でマッピング
  Map<String, List<ShoppingItemDto>> get purchasedItemsByDate {
    final result = <String, List<ShoppingItemDto>>{};
    for (final item in purchasedItems) {
      final at = item.purchasedAt;
      if (at == null) continue;
      final dt = DateTime.tryParse(at);
      if (dt == null) continue;
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  ShoppingListState copyWith({
    List<ShoppingItemDto>? items,
    Object? locationFilter = _sentinel,
    ShoppingTab? activeTab,
    Object? errorMessage = _sentinel,
  }) {
    return ShoppingListState(
      items: items ?? this.items,
      locationFilter: locationFilter == _sentinel
          ? this.locationFilter
          : locationFilter as String?,
      activeTab: activeTab ?? this.activeTab,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

// null をリセット指定と区別するためのセンチネル値
const _sentinel = Object();
