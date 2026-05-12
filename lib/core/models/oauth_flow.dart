enum OAuthFlow {
  link('LINK'),
  login('LOGIN');

  const OAuthFlow(this.code);
  final String code;

  static OAuthFlow? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
