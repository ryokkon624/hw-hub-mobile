import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'login_state.dart';

final loginNotifierProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);

class LoginNotifier extends AutoDisposeNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setEmail(String v) =>
      state = state.copyWith(email: v, errorMessage: null);

  void setPassword(String v) =>
      state = state.copyWith(password: v, errorMessage: null);

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _runCatching(() async {
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
      state = state.copyWith(isLoading: false);
    }, onError: (msg) => state.copyWith(isLoading: false, errorMessage: msg));
  }

  /// AutoDisposeNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    LoginState Function(String errorMessage)? onError,
  }) async {
    try {
      await operation();
    } on AppException catch (e) {
      state = onError != null
          ? onError(e.message)
          : state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = onError != null
          ? onError('errorUnexpected')
          : state.copyWith(errorMessage: 'errorUnexpected');
    }
  }
}
