import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/core/models/auth_user.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/data/models/register_response.dart';

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
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async {});
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

  group('SignupNotifier', () {
    test('初期状態はすべてデフォルト値でcanSubmitはfalse', () {
      final container = makeContainer();
      final state = container.read(signupNotifierProvider);
      expect(state.email, '');
      expect(state.displayName, '');
      expect(state.password, '');
      expect(state.passwordConfirm, '');
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.canSubmit, false);
    });

    test('全フィールド入力（パスワード一致・8文字以上）でcanSubmitがtrue', () {
      final container = makeContainer();
      final n = container.read(signupNotifierProvider.notifier);
      n.setEmail('test@example.com');
      n.setDisplayName('テスト');
      n.setPassword('password123');
      n.setPasswordConfirm('password123');
      expect(container.read(signupNotifierProvider).canSubmit, true);
    });

    test('パスワード7文字ではcanSubmitがfalse', () {
      final container = makeContainer();
      final n = container.read(signupNotifierProvider.notifier);
      n.setEmail('test@example.com');
      n.setDisplayName('テスト');
      n.setPassword('pass123');
      n.setPasswordConfirm('pass123');
      expect(container.read(signupNotifierProvider).canSubmit, false);
    });

    test('パスワード不一致ではcanSubmitがfalse', () {
      final container = makeContainer();
      final n = container.read(signupNotifierProvider.notifier);
      n.setEmail('test@example.com');
      n.setDisplayName('テスト');
      n.setPassword('password123');
      n.setPasswordConfirm('different');
      expect(container.read(signupNotifierProvider).canSubmit, false);
    });

    test('submit() 成功（メール認証必要）でSignupSuccessResultがEmailVerify', () async {
      when(
        mockRepo.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
          locale: anyNamed('locale'),
          invitationToken: anyNamed('invitationToken'),
        ),
      ).thenAnswer(
        (_) async => RegisterResponse(
          emailVerificationRequired: true,
          user: const AuthUser(
            userId: 1,
            email: 'test@example.com',
            displayName: 'テスト',
          ),
        ),
      );

      final container = makeContainer();
      final n = container.read(signupNotifierProvider.notifier);
      n.setEmail('test@example.com');
      n.setDisplayName('テスト');
      n.setPassword('password123');
      n.setPasswordConfirm('password123');
      await n.submit();

      final state = container.read(signupNotifierProvider);
      expect(state.errorMessage, isNull);
      expect(state.successResult?.requiresEmailVerify, true);
      expect(state.successResult?.email, 'test@example.com');
    });

    test(
      'submit() 成功（メール認証不要・トークンあり）: authNotifierがAuthAuthenticated(user)',
      () async {
        const signupUser = AuthUser(
          userId: 1,
          email: 'test@example.com',
          displayName: 'テスト',
        );
        when(
          mockRepo.register(
            email: anyNamed('email'),
            password: anyNamed('password'),
            displayName: anyNamed('displayName'),
            locale: anyNamed('locale'),
            invitationToken: anyNamed('invitationToken'),
          ),
        ).thenAnswer(
          (_) async => RegisterResponse(
            emailVerificationRequired: false,
            accessToken: 'access-jwt',
            refreshToken: 'refresh-jwt',
            user: signupUser,
          ),
        );

        final container = makeContainer();
        await container.read(authNotifierProvider.future);

        final n = container.read(signupNotifierProvider.notifier);
        n.setEmail('test@example.com');
        n.setDisplayName('テスト');
        n.setPassword('password123');
        n.setPasswordConfirm('password123');
        await n.submit();

        final state = container.read(signupNotifierProvider);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNull);
        expect(state.successResult, isNull);

        // authNotifier が user を保持した AuthAuthenticated になること
        final authState = container.read(authNotifierProvider).value;
        expect(authState, isA<AuthAuthenticated>());
        final auth = authState as AuthAuthenticated;
        expect(auth.user.userId, signupUser.userId);
      },
    );

    test('submit() 失敗時にerrorMessageがセットされる', () async {
      when(
        mockRepo.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
          locale: anyNamed('locale'),
          invitationToken: anyNamed('invitationToken'),
        ),
      ).thenThrow(const ServerException(statusCode: 409, message: 'Conflict'));

      final container = makeContainer();
      final n = container.read(signupNotifierProvider.notifier);
      n.setEmail('used@example.com');
      n.setDisplayName('テスト');
      n.setPassword('password123');
      n.setPasswordConfirm('password123');
      await n.submit();

      expect(container.read(signupNotifierProvider).errorMessage, isNotNull);
      expect(container.read(signupNotifierProvider).isLoading, false);
    });
  });
}
