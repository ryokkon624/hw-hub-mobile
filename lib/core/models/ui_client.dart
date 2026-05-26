enum UiClient {
  web('web'),
  mobile('mobile');

  const UiClient(this.code);
  final String code;

  static UiClient? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
