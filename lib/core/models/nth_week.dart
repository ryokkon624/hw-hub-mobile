enum NthWeek {
  firstWeek('1'),
  secondWeek('2'),
  thirdWeek('3'),
  fourthWeek('4'),
  lastWeek('5');

  const NthWeek(this.code);
  final String code;

  static NthWeek? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
