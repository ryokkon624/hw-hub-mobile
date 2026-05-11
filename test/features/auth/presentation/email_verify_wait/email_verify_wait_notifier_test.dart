import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify_wait/email_verify_wait_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/email_verify_wait/email_verify_wait_state.dart';
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

  ProviderContainer makeContainer(String email) {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockRepo),
        emailVerifyWaitNotifierProvider(email),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('EmailVerifyWaitNotifier', () {
    test('初期状態はisSendingがfalse・cooldownが0', () {
      final container = makeContainer('test@example.com');
      final state =
          container.read(emailVerifyWaitNotifierProvider('test@example.com'));
      expect(state.isSending, false);
      expect(state.cooldownSeconds, 0);
      expect(state.errorMessage, isNull);
    });

    test('resend() 成功でcooldownが60から始まる', () async {
      when(mockRepo.resendVerification(email: anyNamed('email')))
          .thenAnswer((_) async {});

      final container = makeContainer('test@example.com');
      await container
          .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
          .resend();

      final state =
          container.read(emailVerifyWaitNotifierProvider('test@example.com'));
      expect(state.isSending, false);
      expect(state.cooldownSeconds, 60);
      expect(state.resentSuccess, true);
    });

    test('resend() 失敗でerrorMessageがセットされる', () async {
      when(mockRepo.resendVerification(email: anyNamed('email')))
          .thenThrow(const NetworkException());

      final container = makeContainer('test@example.com');
      await container
          .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
          .resend();

      final state =
          container.read(emailVerifyWaitNotifierProvider('test@example.com'));
      expect(state.errorMessage, isNotNull);
      expect(state.isSending, false);
    });

    test('resend() isSending=trueのとき（canResend=false）は何もしない', () async {
      final container = makeContainer('test@example.com');
      container
          .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
          .state = const EmailVerifyWaitState(isSending: true);

      await container
          .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
          .resend();

      verifyNever(
          mockRepo.resendVerification(email: anyNamed('email')));
    });

    test('cooldownSeconds > 0のときはcanResendがfalse', () {
      final container = makeContainer('test@example.com');
      container
              .read(
                  emailVerifyWaitNotifierProvider('test@example.com').notifier)
              .state =
          const EmailVerifyWaitState(cooldownSeconds: 30);
      expect(
        container
            .read(emailVerifyWaitNotifierProvider('test@example.com'))
            .canResend,
        false,
      );
    });

    test('resend()成功後1秒経過でcooldownSecondsが59になる', () {
      fakeAsync((fake) {
        when(mockRepo.resendVerification(email: anyNamed('email')))
            .thenAnswer((_) async {});

        final container = makeContainer('test@example.com');
        // AutoDispose を防ぐためにサブスクリプションを保持
        final sub = container.listen(
          emailVerifyWaitNotifierProvider('test@example.com'),
          (_, __) {},
        );

        container
            .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
            .resend();
        fake.flushMicrotasks();

        expect(
          container
              .read(emailVerifyWaitNotifierProvider('test@example.com'))
              .cooldownSeconds,
          60,
        );

        fake.elapse(const Duration(seconds: 1));

        expect(
          container
              .read(emailVerifyWaitNotifierProvider('test@example.com'))
              .cooldownSeconds,
          59,
        );

        sub.close();
      });
    });

    test('resend()成功後60秒経過でcooldownSecondsが0になる', () {
      fakeAsync((fake) {
        when(mockRepo.resendVerification(email: anyNamed('email')))
            .thenAnswer((_) async {});

        final container = makeContainer('test@example.com');
        final sub = container.listen(
          emailVerifyWaitNotifierProvider('test@example.com'),
          (_, __) {},
        );

        container
            .read(emailVerifyWaitNotifierProvider('test@example.com').notifier)
            .resend();
        fake.flushMicrotasks();

        fake.elapse(const Duration(seconds: 60));

        expect(
          container
              .read(emailVerifyWaitNotifierProvider('test@example.com'))
              .cooldownSeconds,
          0,
        );

        sub.close();
      });
    });
  });
}
