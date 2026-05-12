enum AnnouncementScope {
  all('ALL'),
  home('HOME'),
  houseworkAssign('HW_ASSIGN'),
  myTasks('HW_TASK'),
  houseworkSettings('HW_CONF'),
  shopping('SHOPPING'),
  accountSettings('CONF_ACCT'),
  householdSettings('CONF_HH'),
  appSettings('CONF_APP'),
  notification('NOTIFY'),
  inquiry('INQUIRY'),
  admin('ADMIN');

  const AnnouncementScope(this.code);
  final String code;

  static AnnouncementScope? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
