import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';

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

  group('PasswordForgotNotifier', () {
    test('初期状態はemail空・canSubmitはfalse', () {
      final container = makeContainer();
      final state = container.read(passwordForgotNotifierProvider);
      expect(state.email, '');
      expect(state.canSubmit, false);
      expect(state.isLoading, false);
    });

    test('メール入力でcanSubmitがtrue', () {
      final container = makeContainer();
      container
          .read(passwordForgotNotifierProvider.notifier)
          .setEmail('test@example.com');
      expect(container.read(passwordForgotNotifierProvider).canSubmit, true);
    });

    test('submit() 成功でsentEmailがセットされる', () async {
      when(
        mockRepo.requestPasswordReset(email: anyNamed('email')),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      container
          .read(passwordForgotNotifierProvider.notifier)
          .setEmail('test@example.com');
      await container.read(passwordForgotNotifierProvider.notifier).submit();

      final state = container.read(passwordForgotNotifierProvider);
      expect(state.sentEmail, 'test@example.com');
      expect(state.isLoading, false);
    });

    test('submit() 失敗でerrorMessageがセットされる', () async {
      when(
        mockRepo.requestPasswordReset(email: anyNamed('email')),
      ).thenThrow(const NetworkException());

      final container = makeContainer();
      container
          .read(passwordForgotNotifierProvider.notifier)
          .setEmail('test@example.com');
      await container.read(passwordForgotNotifierProvider.notifier).submit();

      expect(
        container.read(passwordForgotNotifierProvider).errorMessage,
        isNotNull,
      );
      expect(container.read(passwordForgotNotifierProvider).isLoading, false);
    });
  });
}
