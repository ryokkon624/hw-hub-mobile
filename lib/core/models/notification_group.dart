enum NotificationGroup {
  household('100'),
  taskAssignment('200'),
  inquiry('900');

  const NotificationGroup(this.code);
  final String code;

  static NotificationGroup? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
