import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/network/auth_interceptor.dart';
import 'package:hw_hub_mobile/core/storage/storage_keys.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';

// テスト用のunauthDio Providerを定義する（AuthInterceptorにRefとmock unauthDioを渡すため）
final _testUnauthDioProvider = Provider<Dio>((ref) => Dio());

// テスト用のAuthInterceptorProviderを定義する
final _authInterceptorTestProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    storage: ref.watch(secureStorageProvider),
    ref: ref,
    unauthDio: ref.watch(_testUnauthDioProvider),
  );
});

// resolve/reject の結果をキャプチャするテスト用ハンドラ
class _CapturingErrorHandler extends ErrorInterceptorHandler {
  DioException? rejectedError;
  Response<dynamic>? resolvedResponse;

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    rejectedError = error;
  }

  @override
  void resolve(Response response) {
    resolvedResponse = response;
  }

  @override
  void next(DioException error) {
    // テストでは next は使用しない
  }
}

// AuthNotifierのフェイク実装（認証済み状態で起動する）
class _AuthenticatedAuthNotifier extends AuthNotifier {
  bool logoutCalled = false;

  @override
  Future<AuthState> build() async {
    return AuthAuthenticated(
      const AuthUser(
        userId: 1,
        email: 'test@example.com',
        displayName: 'テストユーザー',
      ),
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AsyncData(AuthUnauthenticated());
  }
}

// AuthNotifierのフェイク実装（未認証状態で起動する）
class _UnauthenticatedAuthNotifier extends AuthNotifier {
  bool logoutCalled = false;

  @override
  Future<AuthState> build() async {
    return const AuthUnauthenticated();
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AsyncData(AuthUnauthenticated());
  }
}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockDio mockUnauthDio;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockUnauthDio = MockDio();
    SharedPreferences.setMockInitialValues({});

    // デフォルトのスタブ設定
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  /// ProviderContainerと_CapturingErrorHandlerを作って返す
  ProviderContainer makeContainer({
    required AuthNotifier Function() authNotifierFactory,
  }) {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authNotifierProvider.overrideWith(authNotifierFactory),
        _testUnauthDioProvider.overrideWithValue(mockUnauthDio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// テスト用の401 DioExceptionを作成する
  DioException make401Error({String path = '/api/test'}) {
    final requestOptions = RequestOptions(path: path);
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        statusMessage: 'Unauthorized',
      ),
      type: DioExceptionType.badResponse,
    );
  }

  /// テスト用の成功Responseを作成する
  Response<Map<String, dynamic>> makeSuccessResponse({
    String path = '/api/test',
  }) {
    final requestOptions = RequestOptions(path: path);
    return Response<Map<String, dynamic>>(
      requestOptions: requestOptions,
      statusCode: 200,
      data: {'result': 'ok'},
    );
  }

  group('AuthInterceptor', () {
    group('401以外のエラーはそのままnextに渡す', () {
      test('500エラーはリフレッシュせずそのまま通過する', () async {
        final container = makeContainer(
          authNotifierFactory: _AuthenticatedAuthNotifier.new,
        );
        final interceptor = container.read(_authInterceptorTestProvider);

        final requestOptions = RequestOptions(path: '/api/test');
        final error500 = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 500),
          type: DioExceptionType.badResponse,
        );

        final handler = _CapturingErrorHandler();
        await interceptor.onError(error500, handler);

        // 501 エラーはハンドラに何も渡さないが、
        // _CapturingErrorHandler.next()もnullのまま。
        // ここでは reject/resolve が呼ばれないことを確認する
        expect(handler.rejectedError, isNull);
        expect(handler.resolvedResponse, isNull);
      });
    });

    group('リフレッシュトークンなし → ログアウトしUnauthorizedExceptionで拒否', () {
      test(
        'リフレッシュトークンがnullの場合はlogout()を呼び、UnauthorizedExceptionでrejectする',
        () async {
          // refreshToken が null を返すようにモック
          when(
            mockStorage.read(key: StorageKeys.refreshToken),
          ).thenAnswer((_) async => null);

          final fakeAuthNotifier = _AuthenticatedAuthNotifier();
          final container = makeContainer(
            authNotifierFactory: () => fakeAuthNotifier,
          );
          final interceptor = container.read(_authInterceptorTestProvider);

          // AuthNotifierの初期化を待つ
          await container.read(authNotifierProvider.future);

          final handler = _CapturingErrorHandler();
          await interceptor.onError(make401Error(), handler);

          // logout() が呼ばれていること
          expect(fakeAuthNotifier.logoutCalled, isTrue);
          // UnauthorizedExceptionで拒否されていること
          expect(handler.rejectedError, isNotNull);
          expect(handler.rejectedError!.error, isA<UnauthorizedException>());
        },
      );
    });

    group('リフレッシュAPI失敗 → ログアウトしUnauthorizedExceptionで拒否', () {
      test(
        'POST /api/auth/refresh が例外をスローした場合はlogout()を呼び、UnauthorizedExceptionでrejectする',
        () async {
          // refreshToken は存在する
          when(
            mockStorage.read(key: StorageKeys.refreshToken),
          ).thenAnswer((_) async => 'old-refresh-token');

          // refresh API が失敗する
          when(
            mockUnauthDio.post<Map<String, dynamic>>(
              '/api/auth/refresh',
              data: anyNamed('data'),
            ),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: '/api/auth/refresh'),
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: RequestOptions(path: '/api/auth/refresh'),
                statusCode: 401,
              ),
            ),
          );

          final fakeAuthNotifier = _AuthenticatedAuthNotifier();
          final container = makeContainer(
            authNotifierFactory: () => fakeAuthNotifier,
          );
          final interceptor = container.read(_authInterceptorTestProvider);

          await container.read(authNotifierProvider.future);

          final handler = _CapturingErrorHandler();
          await interceptor.onError(make401Error(), handler);

          // logout() が呼ばれていること
          expect(fakeAuthNotifier.logoutCalled, isTrue);
          // UnauthorizedExceptionで拒否されていること
          expect(handler.rejectedError, isNotNull);
          expect(handler.rejectedError!.error, isA<UnauthorizedException>());
        },
      );
    });

    group('リフレッシュ成功 → 元リクエストをリトライし成功レスポンスを返す', () {
      test('POST /api/auth/refresh 成功後に元リクエストをリトライし、resolveで200を返す', () async {
        // refreshToken は存在する
        when(
          mockStorage.read(key: StorageKeys.refreshToken),
        ).thenAnswer((_) async => 'old-refresh-token');

        // refresh API が成功する
        when(
          mockUnauthDio.post<Map<String, dynamic>>(
            '/api/auth/refresh',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            statusCode: 200,
            data: {
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
            },
          ),
        );

        // ストレージへの書き込みを許可する
        when(
          mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
        ).thenAnswer((_) async {});

        // 元リクエストのリトライが成功する
        when(
          mockUnauthDio.fetch<dynamic>(any),
        ).thenAnswer((_) async => makeSuccessResponse());

        final fakeAuthNotifier = _AuthenticatedAuthNotifier();
        final container = makeContainer(
          authNotifierFactory: () => fakeAuthNotifier,
        );
        final interceptor = container.read(_authInterceptorTestProvider);

        await container.read(authNotifierProvider.future);

        final handler = _CapturingErrorHandler();
        await interceptor.onError(make401Error(), handler);

        // logout() が呼ばれていないこと
        expect(fakeAuthNotifier.logoutCalled, isFalse);
        // 成功レスポンスがresolveされていること
        expect(handler.resolvedResponse, isNotNull);
        expect(handler.resolvedResponse!.statusCode, 200);
      });

      test('リフレッシュ後にstorageに新しいトークンが保存される', () async {
        when(
          mockStorage.read(key: StorageKeys.refreshToken),
        ).thenAnswer((_) async => 'old-refresh-token');

        when(
          mockUnauthDio.post<Map<String, dynamic>>(
            '/api/auth/refresh',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/api/auth/refresh'),
            statusCode: 200,
            data: {
              'accessToken': 'new-access-token',
              'refreshToken': 'new-refresh-token',
            },
          ),
        );

        when(
          mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
        ).thenAnswer((_) async {});

        when(
          mockUnauthDio.fetch<dynamic>(any),
        ).thenAnswer((_) async => makeSuccessResponse());

        final container = makeContainer(
          authNotifierFactory: _AuthenticatedAuthNotifier.new,
        );
        final interceptor = container.read(_authInterceptorTestProvider);

        await container.read(authNotifierProvider.future);

        final handler = _CapturingErrorHandler();
        await interceptor.onError(make401Error(), handler);

        // 新しいaccessTokenがstorageに保存されていること
        verify(
          mockStorage.write(
            key: StorageKeys.accessToken,
            value: 'new-access-token',
          ),
        ).called(1);
        // 新しいrefreshTokenがstorageに保存されていること
        verify(
          mockStorage.write(
            key: StorageKeys.refreshToken,
            value: 'new-refresh-token',
          ),
        ).called(1);
      });
    });

    group('既にUnauthenticated状態の場合はlogout()を呼ばない', () {
      test('AuthStateがUnauthenticatedの場合はlogout()を呼ばずそのままrejectする', () async {
        when(
          mockStorage.read(key: StorageKeys.refreshToken),
        ).thenAnswer((_) async => null);

        final fakeAuthNotifier = _UnauthenticatedAuthNotifier();
        final container = makeContainer(
          authNotifierFactory: () => fakeAuthNotifier,
        );
        final interceptor = container.read(_authInterceptorTestProvider);

        await container.read(authNotifierProvider.future);

        final handler = _CapturingErrorHandler();
        await interceptor.onError(make401Error(), handler);

        // 既にUnauthenticatedなのでlogout()は呼ばれない
        expect(fakeAuthNotifier.logoutCalled, isFalse);
        // UnauthorizedExceptionで拒否される
        expect(handler.rejectedError, isNotNull);
        expect(handler.rejectedError!.error, isA<UnauthorizedException>());
      });
    });
  });
}
