enum InquiryCategory {
  general('10'),
  housework('20'),
  shopping('21'),
  accountSettings('30'),
  bugReport('40'),
  other('90');

  const InquiryCategory(this.code);
  final String code;

  static InquiryCategory? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
