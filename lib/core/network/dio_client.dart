import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'app_exception.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({required FlutterSecureStorage storage, required Ref ref}) {
    final unauthDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage: storage, ref: ref, unauthDio: unauthDio),
      _ErrorInterceptor(),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);

    return dio;
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => const NetworkException(),
      DioExceptionType.badResponse => _fromResponse(err.response),
      _ =>
        err.error is AppException
            ? err.error as AppException
            : NetworkException(err.message ?? 'エラーが発生しました'),
    };

    handler.reject(err.copyWith(error: appException));
  }

  AppException _fromResponse(Response? response) {
    final status = response?.statusCode;
    if (status == 401) return const UnauthorizedException();

    final data = response?.data;
    if (data is Map) {
      final code = data['errorCode'] as String?;
      final message = data['message'] as String?;
      if (code != null) {
        return ApiException(message ?? code, code: code);
      }
      return ServerException(
        statusCode: status,
        message: message ?? 'サーバーエラーが発生しました（$status）',
      );
    }

    return ServerException(
      statusCode: status,
      message: 'サーバーエラーが発生しました（$status）',
    );
  }
}
