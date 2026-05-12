enum FavoriteFlag {
  normal('0'),
  favorite('1');

  const FavoriteFlag(this.code);
  final String code;

  static FavoriteFlag? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
