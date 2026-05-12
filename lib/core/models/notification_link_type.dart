enum NotificationLinkType {
  none('None'),
  myTasks('MyTasks'),
  household('Household'),
  invitation('Invite'),
  settings('Settings'),
  inquiryDetail('Inquiry');

  const NotificationLinkType(this.code);
  final String code;

  static NotificationLinkType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
