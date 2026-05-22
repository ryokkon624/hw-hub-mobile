import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/utils/date_format_utils.dart';

void main() {
  group('formatDateTime', () {
    test('ISO文字列をyyyy/MM/dd HH:mm形式に変換する', () {
      expect(formatDateTime('2024-03-15T10:30:00Z'), '2024/03/15 10:30');
    });

    test('月・日・時・分が1桁の場合は0埋めする', () {
      expect(formatDateTime('2024-01-05T09:05:00Z'), '2024/01/05 09:05');
    });

    test('秒・ミリ秒は無視してHH:mmまで表示する', () {
      expect(formatDateTime('2024-06-20T23:59:45.123Z'), '2024/06/20 23:59');
    });

    test('パース不可能な文字列はそのまま返す', () {
      const invalid = 'invalid-date-string';
      expect(formatDateTime(invalid), invalid);
    });

    test('空文字列はそのまま返す', () {
      expect(formatDateTime(''), '');
    });
  });

  group('formatDateTimeWithSeconds', () {
    test('ISO文字列をyyyy/MM/dd HH:mm:ss形式に変換する', () {
      expect(
        formatDateTimeWithSeconds('2024-03-15T10:30:45Z'),
        '2024/03/15 10:30:45',
      );
    });

    test('月・日・時・分・秒が1桁の場合は0埋めする', () {
      expect(
        formatDateTimeWithSeconds('2024-01-05T09:05:03Z'),
        '2024/01/05 09:05:03',
      );
    });

    test('パース不可能な文字列はそのまま返す', () {
      const invalid = 'invalid-date-string';
      expect(formatDateTimeWithSeconds(invalid), invalid);
    });

    test('空文字列はそのまま返す', () {
      expect(formatDateTimeWithSeconds(''), '');
    });
  });
}
