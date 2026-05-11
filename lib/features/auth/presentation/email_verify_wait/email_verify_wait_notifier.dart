import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'email_verify_wait_state.dart';

final emailVerifyWaitNotifierProvider = NotifierProvider.autoDispose
    .family<EmailVerifyWaitNotifier, EmailVerifyWaitState, String>(
      EmailVerifyWaitNotifier.new,
    );

class EmailVerifyWaitNotifier
    extends AutoDisposeFamilyNotifier<EmailVerifyWaitState, String> {
  Timer? _timer;

  @override
  EmailVerifyWaitState build(String email) {
    ref.onDispose(() => _timer?.cancel());
    return const EmailVerifyWaitState();
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    state = state.copyWith(
      isSending: true,
      errorMessage: null,
      resentSuccess: false,
    );
    try {
      await ref.read(authRepositoryProvider).resendVerification(email: arg);
      state = state.copyWith(
        isSending: false,
        cooldownSeconds: 60,
        resentSuccess: true,
      );
      _startCountdown();
    } on AppException catch (e) {
      state = state.copyWith(isSending: false, errorMessage: e.message);
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.cooldownSeconds - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: remaining);
      }
    });
  }
}
