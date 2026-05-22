import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
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

/// HouseholdNotifier のフェイク実装（build呼び出し回数を記録する）
class _TrackingHouseholdNotifier extends HouseholdNotifier {
  int buildCount = 0;

  @override
  Future<HouseholdState> build() async {
    buildCount++;
    return const HouseholdState(households: [], selectedHousehold: null);
  }
}

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

    test('saveTokens() → householdNotifierProvider が再ビルドされる', () async {
      // logout() → エラー状態になった HouseholdNotifier が
      // saveTokens() 後に invalidate されて正常に再ビルドされることを検証する
      final trackingNotifier = _TrackingHouseholdNotifier();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          householdNotifierProvider.overrideWith(() => trackingNotifier),
        ],
      );
      addTearDown(container.dispose);

      // householdNotifierProvider を初期化（build が1回目）
      await container.read(authNotifierProvider.future);
      await container.read(householdNotifierProvider.future);
      final buildCountBeforeSave = trackingNotifier.buildCount;
      expect(buildCountBeforeSave, greaterThanOrEqualTo(1));

      // saveTokens() を呼ぶ
      await container
          .read(authNotifierProvider.notifier)
          .saveTokens(
            accessToken: 'access-jwt',
            refreshToken: 'refresh-jwt',
            user: _testUser,
          );

      // householdNotifierProvider が invalidate され再ビルドされていること
      await container.read(householdNotifierProvider.future);
      expect(trackingNotifier.buildCount, greaterThan(buildCountBeforeSave));
    });

    test(
      'logout() → householdNotifierProvider はエラー状態にならない（invalidate不要）',
      () async {
        // logout() でトークンなしの状態で HouseholdNotifier.build() が走ると
        // 401エラーになりエラー状態になる。logout()ではinvalidateしないことを確認する。
        when(
          mockStorage.read(key: anyNamed('key')),
        ).thenAnswer((_) async => 'some-token');
        when(mockAuthRepo.getMyProfile()).thenAnswer((_) async => _testUser);

        final trackingNotifier = _TrackingHouseholdNotifier();

        final container = ProviderContainer(
          overrides: [
            secureStorageProvider.overrideWithValue(mockStorage),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            householdNotifierProvider.overrideWith(() => trackingNotifier),
          ],
        );
        addTearDown(container.dispose);

        // 認証済み状態にする
        await container.read(authNotifierProvider.future);
        await container.read(householdNotifierProvider.future);
        final buildCountBeforeLogout = trackingNotifier.buildCount;

        // logout() を呼ぶ
        await container.read(authNotifierProvider.notifier).logout();

        // logout() は householdNotifierProvider を invalidate しないため
        // build() が追加で呼ばれないこと
        expect(trackingNotifier.buildCount, buildCountBeforeLogout);
      },
    );
  });
}
