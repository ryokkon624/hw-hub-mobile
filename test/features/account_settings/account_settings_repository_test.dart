import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/account_settings/data/account_settings_repository.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late MockDio mockS3Dio;
  late AccountSettingsRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    mockS3Dio = MockDio();
    repo = AccountSettingsRepositoryImpl(mockDio, mockS3Dio);
  });

  // ==================================
  // fetchProfile
  // ==================================

  group('fetchProfile()', () {
    test('成功時: UserProfileDto を返す', () async {
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/profile'),
          statusCode: 200,
          data: {
            'userId': 1,
            'email': 'test@example.com',
            'authProvider': 'LOCAL',
            'displayName': 'テスト太郎',
            'locale': 'ja',
            'iconUrl': null,
          },
        ),
      );

      final result = await repo.fetchProfile();

      expect(result.userId, 1);
      expect(result.email, 'test@example.com');
      expect(result.authProvider, 'LOCAL');
      expect(result.displayName, 'テスト太郎');
      expect(result.locale, 'ja');
      expect(result.iconUrl, isNull);
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/profile'),
          error: const NetworkException(),
        ),
      );

      expect(() => repo.fetchProfile(), throwsA(isA<AppException>()));
    });
  });

  // ==================================
  // updateProfile
  // ==================================

  group('updateProfile()', () {
    test('成功時: 更新後の UserProfileDto を返す', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/profile', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/profile'),
          statusCode: 200,
          data: {
            'userId': 1,
            'email': 'test@example.com',
            'authProvider': 'LOCAL',
            'displayName': '新しい名前',
            'locale': 'en',
            'iconUrl': null,
          },
        ),
      );

      final result = await repo.updateProfile(
        displayName: '新しい名前',
        locale: 'en',
      );

      expect(result.displayName, '新しい名前');
      expect(result.locale, 'en');
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/profile', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/profile'),
          error: const NetworkException(),
        ),
      );

      expect(
        () => repo.updateProfile(displayName: '名前', locale: 'ja'),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==================================
  // changePassword
  // ==================================

  group('changePassword()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/password', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/password'),
          statusCode: 204,
        ),
      );

      await expectLater(
        repo.changePassword(currentPassword: 'old', newPassword: 'new'),
        completes,
      );
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/password', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/password'),
          error: const ApiException(
            '現在のパスワードが正しくありません',
            code: 'CURRENT_PASSWORD_INVALID',
          ),
        ),
      );

      expect(
        () => repo.changePassword(currentPassword: 'wrong', newPassword: 'new'),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==================================
  // createIconUploadUrl
  // ==================================

  group('createIconUploadUrl()', () {
    test('成功時: uploadUrl と fileKey を含む Map を返す', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/icon/upload-url',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/icon/upload-url'),
          statusCode: 200,
          data: {
            'uploadUrl': 'https://s3.example.com/upload',
            'fileKey': 'user-icon/1/icon.jpg',
          },
        ),
      );

      final result = await repo.createIconUploadUrl(
        fileName: 'icon.jpg',
        mimeType: 'image/jpeg',
      );

      expect(result['uploadUrl'], 'https://s3.example.com/upload');
      expect(result['fileKey'], 'user-icon/1/icon.jpg');
    });
  });

  // ==================================
  // updateIcon
  // ==================================

  group('updateIcon()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.post<dynamic>('/api/users/me/icon', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/icon'),
          statusCode: 200,
        ),
      );

      await expectLater(
        repo.updateIcon(fileKey: 'user-icon/1/icon.jpg'),
        completes,
      );
    });
  });

  // ==================================
  // fetchNotificationSettings
  // ==================================

  group('fetchNotificationSettings()', () {
    test('成功時: NotificationSettingsDto を返す', () async {
      when(
        mockDio.get<dynamic>('/api/users/me/notification-settings'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/notification-settings'),
          statusCode: 200,
          data: {
            'notificationEnabled': true,
            'groupSettings': {'100': true, '200': false},
          },
        ),
      );

      final result = await repo.fetchNotificationSettings();

      expect(result.notificationEnabled, isTrue);
      expect(result.groupSettings['100'], isTrue);
      expect(result.groupSettings['200'], isFalse);
    });
  });

  // ==================================
  // updateNotificationSettings
  // ==================================

  group('updateNotificationSettings()', () {
    test('成功時: 更新後の NotificationSettingsDto を返す', () async {
      final settings = NotificationSettingsDto(
        notificationEnabled: false,
        groupSettings: {'100': false, '200': false},
      );

      when(
        mockDio.put<dynamic>(
          '/api/users/me/notification-settings',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/notification-settings'),
          statusCode: 200,
          data: {
            'notificationEnabled': false,
            'groupSettings': {'100': false, '200': false},
          },
        ),
      );

      final result = await repo.updateNotificationSettings(settings);

      expect(result.notificationEnabled, isFalse);
    });
  });

  // ==================================
  // linkGoogleAccount
  // ==================================

  group('linkGoogleAccount()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/google/link/mobile',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/users/me/google/link/mobile'),
          statusCode: 204,
        ),
      );

      await expectLater(
        repo.linkGoogleAccount(idToken: 'valid-id-token'),
        completes,
      );
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/google/link/mobile',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/google/link/mobile'),
          error: const ApiException(
            'IDトークンが無効です',
            code: 'OAUTH_ID_TOKEN_INVALID',
          ),
        ),
      );

      expect(
        () => repo.linkGoogleAccount(idToken: 'bad-id-token'),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==================================
  // deleteAccount
  // ==================================

  group('deleteAccount()', () {
    test('成功時: 例外なく完了する', () async {
      when(mockDio.delete<dynamic>('/api/users/me')).thenAnswer(
        (_) async =>
            Response(requestOptions: _req('/api/users/me'), statusCode: 204),
      );

      await expectLater(repo.deleteAccount(), completes);
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(mockDio.delete<dynamic>('/api/users/me')).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me'),
          error: const ApiException(
            'OWNERは削除できません',
            code: 'OWNER_CANNOT_DELETE',
          ),
        ),
      );

      expect(() => repo.deleteAccount(), throwsA(isA<AppException>()));
    });
  });
}
