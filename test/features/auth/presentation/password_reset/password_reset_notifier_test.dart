import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset/password_reset_state.dart';
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
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer(String token) {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PasswordResetNotifier', () {
    test('初期状態はフィールド空・canSubmitはfalse', () {
      final container = makeContainer('valid-token');
      final state = container.read(passwordResetNotifierProvider);
      expect(state.password, '');
      expect(state.passwordConfirm, '');
      expect(state.canSubmit('valid-token'), false);
    });

    test('パスワード一致・8文字以上・トークンありでcanSubmitがtrue', () {
      final container = makeContainer('valid-token');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPassword('newpass123');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPasswordConfirm('newpass123');
      expect(
          container.read(passwordResetNotifierProvider).canSubmit('valid-token'),
          true);
    });

    test('パスワード不一致ではcanSubmitがfalse', () {
      final container = makeContainer('valid-token');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPassword('newpass123');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPasswordConfirm('different');
      expect(
          container.read(passwordResetNotifierProvider).canSubmit('valid-token'),
          false);
    });

    test('tokenが空ではcanSubmitがfalse', () {
      final container = makeContainer('');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPassword('newpass123');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPasswordConfirm('newpass123');
      expect(container.read(passwordResetNotifierProvider).canSubmit(''), false);
    });

    test('submit() 成功でPasswordResetResult.successが返る', () async {
      when(mockRepo.confirmPasswordReset(
              token: anyNamed('token'), newPassword: anyNamed('newPassword')))
          .thenAnswer((_) async {});

      final container = makeContainer('valid-token');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPassword('newpass123');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPasswordConfirm('newpass123');
      await container
          .read(passwordResetNotifierProvider.notifier)
          .submit(token: 'valid-token');

      expect(container.read(passwordResetNotifierProvider).result,
          PasswordResetResult.success);
    });

    test('submit() EXPIREDエラーでPasswordResetResult.expiredが返る', () async {
      when(mockRepo.confirmPasswordReset(
              token: anyNamed('token'), newPassword: anyNamed('newPassword')))
          .thenThrow(
              const ApiException('expired', code: 'PASSWORD_RESET_EXPIRED'));

      final container = makeContainer('expired-token');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPassword('newpass123');
      container
          .read(passwordResetNotifierProvider.notifier)
          .setPasswordConfirm('newpass123');
      await container
          .read(passwordResetNotifierProvider.notifier)
          .submit(token: 'expired-token');

      expect(container.read(passwordResetNotifierProvider).result,
          PasswordResetResult.expired);
    });
  });
}
