import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/data/models/auth_user.dart';
import 'package:hw_hub_mobile/features/auth/data/models/login_response.dart';
import 'package:hw_hub_mobile/features/auth/presentation/login/login_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/login/login_state.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth_mocks.mocks.dart';
import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    SharedPreferences.setMockInitialValues({});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LoginNotifier', () {
    test('初期状態はメール・パスワード空でcanSubmitはfalse', () {
      final container = makeContainer();
      final state = container.read(loginNotifierProvider);
      expect(state.email, '');
      expect(state.password, '');
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.canSubmit, false);
    });

    test('メールのみ入力はcanSubmitがfalse', () {
      final container = makeContainer();
      container.read(loginNotifierProvider.notifier).setEmail('test@example.com');
      expect(container.read(loginNotifierProvider).canSubmit, false);
    });

    test('メールとパスワード両方入力でcanSubmitがtrue', () {
      final container = makeContainer();
      container.read(loginNotifierProvider.notifier).setEmail('test@example.com');
      container.read(loginNotifierProvider.notifier).setPassword('password123');
      expect(container.read(loginNotifierProvider).canSubmit, true);
    });

    test('setEmailでerrorMessageがクリアされる', () {
      final container = makeContainer();
      container.read(loginNotifierProvider.notifier)
        ..setEmail('test@example.com')
        ..setPassword('pass');
      // 事前にエラー状態にセット
      container.read(loginNotifierProvider.notifier).state =
          const LoginState(errorMessage: 'エラー');
      container.read(loginNotifierProvider.notifier).setEmail('new@example.com');
      expect(container.read(loginNotifierProvider).errorMessage, isNull);
    });

    test('submit() キャンセル：canSubmitがfalseのときは何もしない', () async {
      final container = makeContainer();
      await container.read(loginNotifierProvider.notifier).submit();
      verifyNever(mockRepo.login(
          email: anyNamed('email'), password: anyNamed('password')));
    });

    test('submit() 成功時にerrorMessageはnullのまま・authNotifierがAuthenticated', () async {
      when(mockRepo.login(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => const LoginResponse(
                accessToken: 'access-jwt',
                refreshToken: 'refresh-jwt',
                user: AuthUser(
                    userId: 1, email: 'test@example.com', displayName: 'Test'),
              ));
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      container.read(loginNotifierProvider.notifier)
        ..setEmail('test@example.com')
        ..setPassword('password123');
      await container.read(loginNotifierProvider.notifier).submit();

      expect(container.read(loginNotifierProvider).errorMessage, isNull);
    });

    test('submit() 失敗時にerrorMessageがセットされisLoadingがfalse', () async {
      when(mockRepo.login(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(const ApiException('認証に失敗しました', code: 'INVALID_CREDENTIALS'));

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      container.read(loginNotifierProvider.notifier)
        ..setEmail('test@example.com')
        ..setPassword('wrongpass');
      await container.read(loginNotifierProvider.notifier).submit();

      final state = container.read(loginNotifierProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNotNull);
    });

    test('submit() ネットワークエラー時もerrorMessageがセットされる', () async {
      when(mockRepo.login(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(const NetworkException());

      final container = makeContainer();
      await container.read(authNotifierProvider.future);

      container.read(loginNotifierProvider.notifier)
        ..setEmail('test@example.com')
        ..setPassword('password123');
      await container.read(loginNotifierProvider.notifier).submit();

      expect(container.read(loginNotifierProvider).errorMessage, isNotNull);
    });
  });
}
