enum PurchaseLocationType {
  supermarket('1'),
  online('2'),
  drugstore('3');

  const PurchaseLocationType(this.code);
  final String code;

  static PurchaseLocationType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
