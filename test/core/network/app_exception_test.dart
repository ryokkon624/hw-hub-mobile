import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';

void main() {
  group('AppException', () {
    test('NetworkException has default message', () {
      const e = NetworkException();
      expect(e.message, 'ネットワークエラーが発生しました');
    });

    test('NetworkException accepts custom message', () {
      const e = NetworkException('接続失敗');
      expect(e.message, '接続失敗');
    });

    test('UnauthorizedException has default message', () {
      const e = UnauthorizedException();
      expect(e.message, '認証が必要です');
    });

    test('ServerException stores statusCode', () {
      const e = ServerException(message: 'Internal Server Error', statusCode: 500);
      expect(e.message, 'Internal Server Error');
      expect(e.statusCode, 500);
    });

    test('ServerException allows null statusCode', () {
      const e = ServerException(message: 'Error');
      expect(e.statusCode, isNull);
    });

    test('ApiException stores code', () {
      const e = ApiException('操作が失敗しました', code: 'INVALID_INPUT');
      expect(e.message, '操作が失敗しました');
      expect(e.code, 'INVALID_INPUT');
    });

    test('sealed class exhaustive switch compiles', () {
      AppException ex = const NetworkException();
      final result = switch (ex) {
        NetworkException() => 'network',
        UnauthorizedException() => 'unauth',
        ServerException() => 'server',
        ApiException() => 'api',
      };
      expect(result, 'network');
    });
  });
}
