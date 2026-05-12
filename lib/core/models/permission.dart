enum Permission {
  userListView('10'),
  roleManagement('11'),
  inquiryReply('20'),
  systemTemplateManagement('30'),
  announcementManagement('40');

  const Permission(this.code);
  final String code;

  static Permission? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
