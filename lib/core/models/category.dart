enum Category {
  pet('PET'),
  cleaning('CLEAN'),
  garbage('GARBAGE'),
  garden('GARDEN'),
  kitchen('KITCHEN'),
  other('OTHER');

  const Category(this.code);
  final String code;

  static Category? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
