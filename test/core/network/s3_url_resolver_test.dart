import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/s3_url_resolver.dart';

void main() {
  group('S3UrlResolver.resolve()', () {
    // isDebugMode=true を渡してテストする（テスト環境ではデバッグモードを制御できないため）
    const resolver = S3UrlResolver(isDebug: true);

    test('null を渡すと null を返す', () {
      expect(resolver.resolve(null), isNull);
    });

    test('localhost を含む URL を 10.0.2.2 に変換する', () {
      const url =
          'http://localhost:4566/hw-hub-bucket/user-icon/1/icon.jpg?X-Amz-Signature=abc';
      final result = resolver.resolve(url);
      expect(result, contains('10.0.2.2'));
      expect(result, isNot(contains('localhost')));
    });

    test('127.0.0.1 を含む URL を 10.0.2.2 に変換する', () {
      const url =
          'http://127.0.0.1:4566/hw-hub-bucket/user-icon/1/icon.jpg?X-Amz-Signature=abc';
      final result = resolver.resolve(url);
      expect(result, contains('10.0.2.2'));
      expect(result, isNot(contains('127.0.0.1')));
    });

    test('S3 本番 URL（localhost/127.0.0.1 を含まない）はそのまま返す', () {
      const url =
          'https://hw-hub-bucket.s3.ap-northeast-1.amazonaws.com/user-icon/1/icon.jpg';
      final result = resolver.resolve(url);
      expect(result, url);
    });

    test('isDebug=false の場合、localhost URL もそのまま返す（本番環境では変換しない）', () {
      const prodResolver = S3UrlResolver(isDebug: false);
      const url = 'http://localhost:4566/hw-hub-bucket/user-icon/1/icon.jpg';
      expect(prodResolver.resolve(url), url);
    });
  });
}
