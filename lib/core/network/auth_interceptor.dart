import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_state.dart';
import '../di/providers.dart';
import '../storage/storage_keys.dart';
import 'app_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Ref ref,
    required Dio unauthDio,
  }) : _storage = storage,
       _ref = ref,
       _unauthDio = unauthDio;

  final FlutterSecureStorage _storage;
  final Ref _ref;
  final Dio _unauthDio;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

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
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // 別リクエストがリフレッシュ中 → 完了を待ってリトライ
    if (_isRefreshing) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          handler.resolve(await _unauthDio.fetch(err.requestOptions));
        } catch (_) {
          handler.reject(err);
        }
      } else {
        handler.reject(err.copyWith(error: const UnauthorizedException()));
      }
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final newToken = await _doRefresh();
      _refreshCompleter!.complete(newToken);

      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        handler.resolve(await _unauthDio.fetch(err.requestOptions));
      } else {
        await _logoutIfAuthenticated();
        handler.reject(err.copyWith(error: const UnauthorizedException()));
      }
    } catch (_) {
      _refreshCompleter!.complete(null);
      await _logoutIfAuthenticated();
      handler.reject(err.copyWith(error: const UnauthorizedException()));
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// 既に AuthUnauthenticated 状態（または logout 処理中）の場合は logout() を呼ばない。
  /// これにより、logout 直後に invalidate された Provider の API 呼び出しが 401 になっても
  /// logout() が再入して無限ループになるのを防ぐ。
  Future<void> _logoutIfAuthenticated() async {
    final authState = _ref.read(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;
    await _ref.read(authNotifierProvider.notifier).logout();
  }

  Future<String?> _doRefresh() async {
    // TODO: POST /api/auth/refresh バックエンド実装後に追加
    // final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    // if (refreshToken == null) return null;
    // final res = await _unauthDio.post('/api/auth/refresh',
    //     data: {'refreshToken': refreshToken});
    // final newAccess = res.data['accessToken'] as String;
    // final newRefresh = res.data['refreshToken'] as String;
    // await _ref.read(authNotifierProvider.notifier).saveTokens(
    //       accessToken: newAccess, refreshToken: newRefresh);
    // return newAccess;
    return null;
  }
}
