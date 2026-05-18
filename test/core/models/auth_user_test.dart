import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';

void main() {
  group('AuthUser', () {
    group('fromJson', () {
      test('iconUrlありのJSONをパースできる', () {
        final json = {
          'userId': 1,
          'email': 'test@example.com',
          'displayName': 'テスト',
          'iconUrl': 'https://example.com/icon.png',
        };

        final user = AuthUser.fromJson(json);

        expect(user.userId, 1);
        expect(user.email, 'test@example.com');
        expect(user.displayName, 'テスト');
        expect(user.iconUrl, 'https://example.com/icon.png');
      });

      test('iconUrlなし（null）のJSONをパースできる', () {
        final json = {
          'userId': 1,
          'email': 'test@example.com',
          'displayName': 'テスト',
          'iconUrl': null,
        };

        final user = AuthUser.fromJson(json);

        expect(user.iconUrl, isNull);
      });

      test('iconUrlキーが存在しないJSONをパースできる', () {
        final json = {
          'userId': 1,
          'email': 'test@example.com',
          'displayName': 'テスト',
        };

        final user = AuthUser.fromJson(json);

        expect(user.iconUrl, isNull);
      });
    });

    group('コンストラクタ', () {
      test('iconUrlなしで生成できる（既存互換）', () {
        const user = AuthUser(
          userId: 1,
          email: 'test@example.com',
          displayName: 'テスト',
        );

        expect(user.iconUrl, isNull);
      });

      test('iconUrlありで生成できる', () {
        const user = AuthUser(
          userId: 1,
          email: 'test@example.com',
          displayName: 'テスト',
          iconUrl: 'https://example.com/icon.png',
        );

        expect(user.iconUrl, 'https://example.com/icon.png');
      });
    });
  });
}
