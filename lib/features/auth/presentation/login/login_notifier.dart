import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'login_state.dart';

final loginNotifierProvider = NotifierProvider<LoginNotifier, LoginState>(
  LoginNotifier.new,
);

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setEmail(String v) =>
      state = state.copyWith(email: v, errorMessage: null);

  void setPassword(String v) =>
      state = state.copyWith(password: v, errorMessage: null);

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await ref
          .read(authRepositoryProvider)
          .login(email: state.email, password: state.password);
      await ref
          .read(authNotifierProvider.notifier)
          .saveTokens(
            accessToken: resp.accessToken,
            refreshToken: resp.refreshToken,
            user: resp.user,
          );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
