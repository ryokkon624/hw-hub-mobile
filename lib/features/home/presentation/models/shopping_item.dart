/// プレゼンテーション層で使う買い物アイテムモデル
class ShoppingItem {
  const ShoppingItem({
    required this.shoppingItemId,
    required this.name,
    this.storeType,
    required this.status,
    required this.createdAt,
  });

  final int shoppingItemId;
  final String name;
  final String? storeType;
  final String status; // "0"=open, "1"=purchased
  final String createdAt; // ISO datetime string
}
