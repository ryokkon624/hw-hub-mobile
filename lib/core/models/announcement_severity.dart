enum AnnouncementSeverity {
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  const AnnouncementSeverity(this.code);
  final String code;

  static AnnouncementSeverity? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
