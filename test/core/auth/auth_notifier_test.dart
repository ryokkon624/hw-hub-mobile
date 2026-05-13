import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';

const _testUser = AuthUser(
  userId: 42,
  email: 'test@example.com',
  displayName: 'テスト',
);

final _userJson = <String, dynamic>{
  'userId': _testUser.userId,
  'email': _testUser.email,
  'displayName': _testUser.displayName,
};

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockDio mockDio;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockDio = MockDio();
    SharedPreferences.setMockInitialValues({});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        dioProvider.overrideWithValue(mockDio),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthState', () {
    test('AuthLoading はAuthStateのサブタイプ', () {
      expect(const AuthLoading(), isA<AuthState>());
    });
  });

  group('AuthNotifier', () {
    test('build() トークンなし → Unauthenticated', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthUnauthenticated>());
    });

    test('build() トークンあり・/me 成功 → Authenticated(user)', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => 'some-token');
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/users/me/profile'),
          statusCode: 200,
          data: _userJson,
        ),
      );

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthAuthenticated>());
      final auth = state as AuthAuthenticated;
      expect(auth.user.userId, _testUser.userId);
      expect(auth.user.email, _testUser.email);
    });

    test('build() トークンあり・/me 失敗 → Unauthenticated', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => 'some-token');
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/users/me/profile'),
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
      );

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthUnauthenticated>());
    });

    test('saveTokens(user:) → Authenticated(user)状態になる', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container
          .read(authNotifierProvider.notifier)
          .saveTokens(
            accessToken: 'access-jwt',
            refreshToken: 'refresh-jwt',
            user: _testUser,
          );

      final result = container.read(authNotifierProvider).value;
      expect(result, isA<AuthAuthenticated>());
      final auth = result as AuthAuthenticated;
      expect(auth.user.userId, _testUser.userId);
    });

    test('logout() → Unauthenticated状態になる', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => 'some-token');
      when(mockDio.get<dynamic>('/api/users/me/profile')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/users/me/profile'),
          statusCode: 200,
          data: _userJson,
        ),
      );

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container.read(authNotifierProvider.notifier).logout();

      expect(
        container.read(authNotifierProvider).value,
        isA<AuthUnauthenticated>(),
      );
    });
  });
}
