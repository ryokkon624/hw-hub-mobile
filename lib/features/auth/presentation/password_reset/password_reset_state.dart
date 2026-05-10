enum PasswordResetResult { success, expired, invalid }

class PasswordResetState {
  const PasswordResetState({
    this.password = '',
    this.passwordConfirm = '',
    this.isLoading = false,
    this.errorMessage,
    this.result,
  });

  final String password;
  final String passwordConfirm;
  final bool isLoading;
  final String? errorMessage;
  final PasswordResetResult? result;

  bool canSubmit(String token) =>
      token.isNotEmpty &&
      password.length >= 8 &&
      password == passwordConfirm &&
      !isLoading;

  bool get hasMismatch =>
      passwordConfirm.isNotEmpty && password != passwordConfirm;

  PasswordResetState copyWith({
    String? password,
    String? passwordConfirm,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? result = _sentinel,
  }) =>
      PasswordResetState(
        password: password ?? this.password,
        passwordConfirm: passwordConfirm ?? this.passwordConfirm,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        result: result == _sentinel
            ? this.result
            : result as PasswordResetResult?,
      );

  static const _sentinel = Object();
}
