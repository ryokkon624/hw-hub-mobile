enum Weekday {
  sunday('0'),
  monday('1'),
  tuesday('2'),
  wednesday('3'),
  thursday('4'),
  friday('5'),
  saturday('6');

  const Weekday(this.code);
  final String code;

  static Weekday? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
