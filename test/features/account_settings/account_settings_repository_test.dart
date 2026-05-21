import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/network/s3_url_resolver.dart';
import 'package:hw_hub_mobile/features/account_settings/data/account_settings_repository.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

RequestOptions _req(String path) => RequestOptions(path: path);

/// テスト用の S3UrlResolver（isDebug=true で localhost → 10.0.2.2 に変換する）
const _debugResolver = S3UrlResolver(isDebug: true);

void main() {
  late MockDio mockDio;
  late MockDio mockS3Dio;
  late AccountSettingsRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    mockS3Dio = MockDio();
    repo = AccountSettingsRepositoryImpl(mockDio, mockS3Dio, _debugResolver);
  });

  // ==================================
  // fetchProfile
  // ==================================

  group('fetchProfile()', () {
    test('成功時: UserProfileDto を返す（iconUrl が null の場合）', () async {
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

    test('成功時: iconUrl が localhost URL の場合に 10.0.2.2 に変換される', () async {
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
            'iconUrl':
                'http://localhost:4566/hw-hub-bucket/user-icon/1/icon.jpg',
          },
        ),
      );

      final result = await repo.fetchProfile();

      expect(result.iconUrl, contains('10.0.2.2'));
      expect(result.iconUrl, isNot(contains('localhost')));
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

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/icon/upload-url',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/icon/upload-url'),
          error: const NetworkException(),
        ),
      );

      expect(
        () => repo.createIconUploadUrl(
          fileName: 'icon.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  // ==================================
  // uploadToS3
  // ==================================

  group('uploadToS3()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockS3Dio.put<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('https://s3.example.com/upload'),
          statusCode: 200,
        ),
      );

      await expectLater(
        repo.uploadToS3(
          uploadUrl: 'https://s3.example.com/upload',
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        ),
        completes,
      );
    });

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockS3Dio.put<dynamic>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('https://s3.example.com/upload'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.uploadToS3(
          uploadUrl: 'https://s3.example.com/upload',
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<NetworkException>()),
      );
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

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.post<dynamic>('/api/users/me/icon', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/icon'),
          error: const NetworkException(),
        ),
      );

      expect(
        () => repo.updateIcon(fileKey: 'user-icon/1/icon.jpg'),
        throwsA(isA<AppException>()),
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

    test('DioException 発生時: AppException を再スロー', () async {
      when(
        mockDio.get<dynamic>('/api/users/me/notification-settings'),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/notification-settings'),
          error: const NetworkException(),
        ),
      );

      expect(
        () => repo.fetchNotificationSettings(),
        throwsA(isA<AppException>()),
      );
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

    test('DioException 発生時: AppException を再スロー', () async {
      final settings = NotificationSettingsDto(
        notificationEnabled: true,
        groupSettings: {'100': true},
      );

      when(
        mockDio.put<dynamic>(
          '/api/users/me/notification-settings',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/notification-settings'),
          error: const NetworkException(),
        ),
      );

      expect(
        () => repo.updateNotificationSettings(settings),
        throwsA(isA<AppException>()),
      );
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

  // ==================================
  // NetworkException fallback（e.error が AppException でない場合）
  // ==================================

  group('NetworkException fallback（e.error が AppException でない場合）', () {
    test('fetchProfile: NetworkException をスロー', () async {
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/profile'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(() => repo.fetchProfile(), throwsA(isA<NetworkException>()));
    });

    test('updateProfile: NetworkException をスロー', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/profile', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/profile'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateProfile(displayName: '名前', locale: 'ja'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('changePassword: NetworkException をスロー', () async {
      when(
        mockDio.put<dynamic>('/api/users/me/password', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/password'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.changePassword(currentPassword: 'old', newPassword: 'new'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('createIconUploadUrl: NetworkException をスロー', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/icon/upload-url',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/icon/upload-url'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createIconUploadUrl(
          fileName: 'icon.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<NetworkException>()),
      );
    });

    test('updateIcon: NetworkException をスロー', () async {
      when(
        mockDio.post<dynamic>('/api/users/me/icon', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/icon'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateIcon(fileKey: 'user-icon/1/icon.jpg'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('fetchNotificationSettings: NetworkException をスロー', () async {
      when(
        mockDio.get<dynamic>('/api/users/me/notification-settings'),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/notification-settings'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchNotificationSettings(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('updateNotificationSettings: NetworkException をスロー', () async {
      final settings = NotificationSettingsDto(
        notificationEnabled: true,
        groupSettings: {},
      );
      when(
        mockDio.put<dynamic>(
          '/api/users/me/notification-settings',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/notification-settings'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateNotificationSettings(settings),
        throwsA(isA<NetworkException>()),
      );
    });

    test('linkGoogleAccount: NetworkException をスロー', () async {
      when(
        mockDio.post<dynamic>(
          '/api/users/me/google/link/mobile',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me/google/link/mobile'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.linkGoogleAccount(idToken: 'bad-token'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('deleteAccount: NetworkException をスロー', () async {
      when(mockDio.delete<dynamic>('/api/users/me')).thenThrow(
        DioException(
          requestOptions: _req('/api/users/me'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(() => repo.deleteAccount(), throwsA(isA<NetworkException>()));
    });
  });
}
