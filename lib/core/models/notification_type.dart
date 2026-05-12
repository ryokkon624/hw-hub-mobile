enum NotificationType {
  invitationAccepted('0101'),
  invitationDeclined('0102'),
  haveBeenRemoved('0201'),
  leftTheHousehold('0202'),
  assignedToTheOwner('0203'),
  taskAssigned('0301'),
  beDumpedTask('0302'),
  yourTaskWasTaken('0303'),
  yourInquiryHasBeenReplied('0401');

  const NotificationType(this.code);
  final String code;

  static NotificationType? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
