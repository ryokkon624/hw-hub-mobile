enum RecurrenceType {
  weekly('1'),
  monthly('2'),
  nthWeekday('3');

  const RecurrenceType(this.code);
  final String code;

  static RecurrenceType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
