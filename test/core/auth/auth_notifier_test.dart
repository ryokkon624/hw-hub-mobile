import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/storage/storage_keys.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';
import '../../features/auth/auth_mocks.mocks.dart';

const _testUser = AuthUser(
  userId: 42,
  email: 'test@example.com',
  displayName: 'テスト',
);

void main() {
  late MockFlutterSecureStorage mockStorage;
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockAuthRepo = MockAuthRepository();
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
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
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

    test('build() トークンあり・getMyProfile 成功 → Authenticated(user)', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => 'some-token');
      when(mockAuthRepo.getMyProfile()).thenAnswer((_) async => _testUser);

      final container = makeContainer();
      final state = await container.read(authNotifierProvider.future);

      expect(state, isA<AuthAuthenticated>());
      final auth = state as AuthAuthenticated;
      expect(auth.user.userId, _testUser.userId);
      expect(auth.user.email, _testUser.email);
    });

    test('build() トークンあり・getMyProfile 失敗 → Unauthenticated', () async {
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => 'some-token');
      when(mockAuthRepo.getMyProfile()).thenThrow(const NetworkException());

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
      when(mockAuthRepo.getMyProfile()).thenAnswer((_) async => _testUser);

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      await container.read(authNotifierProvider.notifier).logout();

      expect(
        container.read(authNotifierProvider).value,
        isA<AuthUnauthenticated>(),
      );
    });

    test('logout() → SharedPreferences の selectedHouseholdId が削除される', () async {
      // ログイン前にselectedHouseholdIdを設定しておく
      SharedPreferences.setMockInitialValues({
        StorageKeys.selectedHouseholdId: 42,
      });
      when(
        mockStorage.read(key: anyNamed('key')),
      ).thenAnswer((_) async => null);

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      // ログアウト前は selectedHouseholdId が存在する
      final prefsBeforeLogout = await SharedPreferences.getInstance();
      expect(prefsBeforeLogout.getInt(StorageKeys.selectedHouseholdId), 42);

      await container.read(authNotifierProvider.notifier).logout();

      // ログアウト後は selectedHouseholdId が削除されている
      final prefsAfterLogout = await SharedPreferences.getInstance();
      expect(prefsAfterLogout.getInt(StorageKeys.selectedHouseholdId), isNull);
    });
  });
}
