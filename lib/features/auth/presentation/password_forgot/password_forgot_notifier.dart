import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'password_forgot_state.dart';

final passwordForgotNotifierProvider =
    NotifierProvider<PasswordForgotNotifier, PasswordForgotState>(
      PasswordForgotNotifier.new,
    );

class PasswordForgotNotifier extends Notifier<PasswordForgotState> {
  @override
  PasswordForgotState build() => const PasswordForgotState();

  void setEmail(String v) =>
      state = state.copyWith(email: v, errorMessage: null);

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: state.email);
      state = state.copyWith(isLoading: false, sentEmail: state.email);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
