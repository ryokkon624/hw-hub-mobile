import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/password_reset_sent/password_reset_sent_notifier.dart';

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

  ProviderContainer makeContainer(String email) {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockRepo),
        passwordResetSentNotifierProvider(email),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('PasswordResetSentNotifier', () {
    test('初期状態はisSendingがfalse', () {
      final container = makeContainer('test@example.com');
      final state = container
          .read(passwordResetSentNotifierProvider('test@example.com'));
      expect(state.isSending, false);
      expect(state.errorMessage, isNull);
    });

    test('resend() 成功でresentSuccessがtrue', () async {
      when(mockRepo.requestPasswordReset(email: anyNamed('email')))
          .thenAnswer((_) async {});

      final container = makeContainer('test@example.com');
      await container
          .read(passwordResetSentNotifierProvider('test@example.com').notifier)
          .resend();

      final state = container
          .read(passwordResetSentNotifierProvider('test@example.com'));
      expect(state.isSending, false);
      expect(state.resentSuccess, true);
    });

    test('resend() 失敗でerrorMessageがセットされる', () async {
      when(mockRepo.requestPasswordReset(email: anyNamed('email')))
          .thenThrow(const NetworkException());

      final container = makeContainer('test@example.com');
      await container
          .read(passwordResetSentNotifierProvider('test@example.com').notifier)
          .resend();

      expect(
        container
            .read(passwordResetSentNotifierProvider('test@example.com'))
            .errorMessage,
        isNotNull,
      );
    });
  });
}
