enum ShoppingItemStatus {
  notPurchased('0'),
  inBasket('1'),
  purchased('9');

  const ShoppingItemStatus(this.code);
  final String code;

  static ShoppingItemStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
