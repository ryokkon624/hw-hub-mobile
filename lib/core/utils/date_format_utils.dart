// ISO 8601 形式の日時文字列を表示用にフォーマットするユーティリティ。
// パース失敗時は入力文字列をそのまま返す。

/// `yyyy/MM/dd HH:mm` 形式に変換する。
String formatDateTime(String isoString) {
  try {
    final dt = DateTime.parse(isoString);
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y/$mo/$d $h:$mi';
  } catch (_) {
    return isoString;
  }
}

/// `yyyy/MM/dd HH:mm:ss` 形式に変換する（秒を含む）。
String formatDateTimeWithSeconds(String isoString) {
  try {
    final dt = DateTime.parse(isoString);
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y/$mo/$d $h:$mi:$s';
  } catch (_) {
    return isoString;
  }
}
