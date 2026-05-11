class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;

  bool get canSubmit =>
      email.trim().isNotEmpty && password.isNotEmpty && !isLoading;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
  );

  static const _sentinel = Object();
}
