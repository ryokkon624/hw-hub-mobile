enum InquiryStatus {
  open('00'),
  aiAnswered('10'),
  pendingStaff('20'),
  staffAnswered('25'),
  closed('90');

  const InquiryStatus(this.code);
  final String code;

  static InquiryStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
