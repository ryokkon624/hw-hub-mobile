enum SenderType {
  you('USER'),
  aiSupport('AI'),
  staff('STAFF');

  const SenderType(this.code);
  final String code;

  static SenderType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
