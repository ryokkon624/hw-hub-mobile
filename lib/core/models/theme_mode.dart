enum ThemeMode {
  system('SYSTEM'),
  light('LIGHT'),
  dark('DARK');

  const ThemeMode(this.code);
  final String code;

  static ThemeMode? fromCode(String? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
