import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'signup_state.dart';

final signupNotifierProvider = NotifierProvider<SignupNotifier, SignupState>(
  SignupNotifier.new,
);

class SignupNotifier extends Notifier<SignupState> {
  @override
  SignupState build() => const SignupState();

  void setEmail(String v) =>
      state = state.copyWith(email: v, errorMessage: null);
  void setDisplayName(String v) => state = state.copyWith(displayName: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setPasswordConfirm(String v) =>
      state = state.copyWith(passwordConfirm: v);
  void setLocale(String v) => state = state.copyWith(locale: v);

  Future<void> submit({String? invitationToken}) async {
    if (!state.canSubmit) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await ref
          .read(authRepositoryProvider)
          .register(
            email: state.email,
            password: state.password,
            displayName: state.displayName,
            locale: state.locale,
            invitationToken: invitationToken,
          );
      if (!resp.emailVerificationRequired &&
          resp.accessToken != null &&
          resp.refreshToken != null) {
        await ref
            .read(authNotifierProvider.notifier)
            .saveTokens(
              accessToken: resp.accessToken!,
              refreshToken: resp.refreshToken!,
              user: resp.user,
            );
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          successResult: SignupSuccessResult(
            email: state.email,
            requiresEmailVerify: resp.emailVerificationRequired,
          ),
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
