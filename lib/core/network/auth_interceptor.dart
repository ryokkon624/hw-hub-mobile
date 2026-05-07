import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/storage_keys.dart';
import 'app_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Phase 2 auth: ここにリフレッシュトークン（Flag + Queue）パターンを実装する
      handler.reject(
        err.copyWith(
          error: const UnauthorizedException(),
        ),
      );
      return;
    }
    handler.next(err);
  }
}
