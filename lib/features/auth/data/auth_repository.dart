import 'package:dio/dio.dart';

import '../../../core/models/auth_user.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/s3_url_resolver.dart';
import 'auth_api.dart';
import 'models/invitation_info.dart';
import 'models/login_response.dart';
import 'models/register_response.dart';

abstract interface class AuthRepository {
  Future<AuthUser> getMyProfile();

  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  Future<LoginResponse> googleLoginMobile({required String idToken});

  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String displayName,
    required String locale,
    String? invitationToken,
  });

  Future<void> resendVerification({required String email});

  Future<void> verifyEmail({required String token});

  Future<void> requestPasswordReset({required String email});

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  });

  Future<InvitationInfo> getInvitation({required String token});

  Future<void> acceptInvitation({required String token});

  Future<void> declineInvitation({required String token});
}

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthApi api,
    required S3UrlResolver s3UrlResolver,
  }) : _api = api,
       _s3UrlResolver = s3UrlResolver;

  final AuthApi _api;
  final S3UrlResolver _s3UrlResolver;

  AppException _convert(DioException e) => e.error is AppException
      ? e.error as AppException
      : const NetworkException();

  @override
  Future<AuthUser> getMyProfile() async {
    try {
      final user = await _api.getMyProfile();
      // LocalStack 環境では iconUrl が localhost URL のため、変換して返す
      return AuthUser(
        userId: user.userId,
        email: user.email,
        displayName: user.displayName,
        iconUrl: _s3UrlResolver.resolve(user.iconUrl),
      );
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _api.login({'email': email, 'password': password});
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<LoginResponse> googleLoginMobile({required String idToken}) async {
    try {
      return await _api.googleLoginMobile({'idToken': idToken});
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String displayName,
    required String locale,
    String? invitationToken,
  }) async {
    try {
      return await _api.register({
        'email': email,
        'password': password,
        'displayName': displayName,
        'locale': locale,
        'invitationToken': invitationToken,
      });
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> resendVerification({required String email}) async {
    try {
      await _api.resendVerification({'email': email});
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> verifyEmail({required String token}) async {
    try {
      await _api.verifyEmail({'token': token});
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _api.requestPasswordReset({'email': email});
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _api.confirmPasswordReset({
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<InvitationInfo> getInvitation({required String token}) async {
    try {
      return await _api.getInvitation(token);
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> acceptInvitation({required String token}) async {
    try {
      await _api.acceptInvitation(token);
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> declineInvitation({required String token}) async {
    try {
      await _api.declineInvitation(token);
    } on DioException catch (e) {
      throw _convert(e);
    }
  }
}
