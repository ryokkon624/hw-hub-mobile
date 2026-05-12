enum EventStatus {
  pending('0'),
  processing('1'),
  done('2');

  const EventStatus(this.code);
  final String code;

  static EventStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
