import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    SharedPreferences.setMockInitialValues({});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(mockStorage)],
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
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthUnauthenticated>());
    });

    test('build() トークンあり → Authenticated', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => 'some-token');

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthAuthenticated>());
    });

    test('saveTokens() → Authenticated状態になる', () async {
      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container.read(authNotifierProvider.notifier).saveTokens(
            accessToken: 'access-jwt',
            refreshToken: 'refresh-jwt',
          );

      expect(
        container.read(authNotifierProvider).value,
        isA<AuthAuthenticated>(),
      );
    });

    test('logout() → Unauthenticated状態になる', () async {
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => 'some-token');

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
