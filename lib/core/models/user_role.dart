enum UserRole {
  admin('ADMIN'),
  support('SPPRT');

  const UserRole(this.code);
  final String code;

  static UserRole? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
