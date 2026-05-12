enum NotificationStatus {
  active('1'),
  inactive('0');

  const NotificationStatus(this.code);
  final String code;

  static NotificationStatus? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
