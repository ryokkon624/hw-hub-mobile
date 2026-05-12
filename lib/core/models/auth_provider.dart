enum AuthProvider {
  local('LOCAL'),
  google('GOOGLE');

  const AuthProvider(this.code);
  final String code;

  static AuthProvider? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
