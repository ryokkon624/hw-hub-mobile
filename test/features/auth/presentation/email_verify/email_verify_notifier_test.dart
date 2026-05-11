import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify/email_verify_notifier.dart';
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

  group('EmailVerifyNotifier', () {
    test('tokenが空のときはinvalidResultをすぐに返す', () async {
      final container = makeContainer('');
      final result = await container.read(emailVerifyResultProvider('').future);
      expect(result, EmailVerifyResult.invalid);
    });

    test('API成功でsuccessResultを返す', () async {
      when(
        mockRepo.verifyEmail(token: anyNamed('token')),
      ).thenAnswer((_) async {});

      final container = makeContainer('valid-token');
      final result = await container.read(
        emailVerifyResultProvider('valid-token').future,
      );
      expect(result, EmailVerifyResult.success);
    });

    test('EMAIL_VERIFY_EXPIREDエラーでexpiredResultを返す', () async {
      when(
        mockRepo.verifyEmail(token: anyNamed('token')),
      ).thenThrow(const ApiException('expired', code: 'EMAIL_VERIFY_EXPIRED'));

      final container = makeContainer('expired-token');
      final result = await container.read(
        emailVerifyResultProvider('expired-token').future,
      );
      expect(result, EmailVerifyResult.expired);
    });

    test('その他エラーでinvalidResultを返す', () async {
      when(
        mockRepo.verifyEmail(token: anyNamed('token')),
      ).thenThrow(const ApiException('invalid', code: 'EMAIL_VERIFY_INVALID'));

      final container = makeContainer('bad-token');
      final result = await container.read(
        emailVerifyResultProvider('bad-token').future,
      );
      expect(result, EmailVerifyResult.invalid);
    });
  });
}
