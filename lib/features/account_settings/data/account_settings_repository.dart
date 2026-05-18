import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/app_exception.dart';
import 'models/notification_settings_dto.dart';
import 'models/user_profile_dto.dart';

export 'models/notification_settings_dto.dart';
export 'models/user_profile_dto.dart';

abstract class AccountSettingsRepository {
  /// プロフィールを取得する。
  Future<UserProfileDto> fetchProfile();

  /// プロフィール（表示名・言語）を更新する。
  Future<UserProfileDto> updateProfile({
    required String displayName,
    required String locale,
  });

  /// パスワードを変更する。
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// アイコンアップロード用 Presigned URL を取得する。
  Future<Map<String, String>> createIconUploadUrl({
    required String fileName,
    required String mimeType,
  });

  /// S3 に画像を直接 PUT する（インターセプターなしの素の Dio を使用）。
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  });

  /// アイコンを更新する（S3 アップロード後の fileKey 登録）。
  Future<void> updateIcon({required String fileKey});

  /// 通知設定を取得する。
  Future<NotificationSettingsDto> fetchNotificationSettings();

  /// 通知設定を更新する。
  Future<NotificationSettingsDto> updateNotificationSettings(
    NotificationSettingsDto settings,
  );

  /// Google アカウントをモバイル用 IDトークンで連携する。
  Future<void> linkGoogleAccount({required String idToken});

  /// アカウントを削除する（論理削除）。
  Future<void> deleteAccount();
}

class AccountSettingsRepositoryImpl implements AccountSettingsRepository {
  AccountSettingsRepositoryImpl(this._dio, this._s3Dio);

  final Dio _dio;
  final Dio _s3Dio; // S3 直接 PUT 用（インターセプターなし）

  @override
  Future<UserProfileDto> fetchProfile() async {
    try {
      final response = await _dio.get<dynamic>('/api/users/me/profile');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<UserProfileDto> updateProfile({
    required String displayName,
    required String locale,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/users/me/profile',
        data: {'displayName': displayName, 'locale': locale},
      );
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/api/users/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<Map<String, String>> createIconUploadUrl({
    required String fileName,
    required String mimeType,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/users/me/icon/upload-url',
        data: {'fileName': fileName, 'mimeType': mimeType},
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'uploadUrl': data['uploadUrl'] as String,
        'fileKey': data['fileKey'] as String,
      };
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  String _resolveS3Url(String url) {
    if (!kDebugMode) return url;
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }

  @override
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final resolved = _resolveS3Url(uploadUrl);
      await _s3Dio.put<dynamic>(
        resolved,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {'Content-Type': mimeType, 'Content-Length': bytes.length},
        ),
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> updateIcon({required String fileKey}) async {
    try {
      await _dio.post<dynamic>(
        '/api/users/me/icon',
        data: {'fileKey': fileKey},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<NotificationSettingsDto> fetchNotificationSettings() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/users/me/notification-settings',
      );
      return NotificationSettingsDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<NotificationSettingsDto> updateNotificationSettings(
    NotificationSettingsDto settings,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/users/me/notification-settings',
        data: settings.toUpdateJson(),
      );
      return NotificationSettingsDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> linkGoogleAccount({required String idToken}) async {
    try {
      await _dio.post<dynamic>(
        '/api/users/me/google/link/mobile',
        data: {'idToken': idToken},
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<dynamic>('/api/users/me');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
