import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'password_reset_state.dart';

final passwordResetNotifierProvider =
    NotifierProvider<PasswordResetNotifier, PasswordResetState>(
      PasswordResetNotifier.new,
    );

class PasswordResetNotifier extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() => const PasswordResetState();

  void setPassword(String v) => state = state.copyWith(password: v);
  void setPasswordConfirm(String v) =>
      state = state.copyWith(passwordConfirm: v);

  Future<void> submit({required String token}) async {
    if (!state.canSubmit(token)) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPasswordReset(token: token, newPassword: state.password);
      state = state.copyWith(
        isLoading: false,
        result: PasswordResetResult.success,
      );
    } on ApiException catch (e) {
      final r = e.code == 'PASSWORD_RESET_EXPIRED'
          ? PasswordResetResult.expired
          : PasswordResetResult.invalid;
      state = state.copyWith(isLoading: false, result: r);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
