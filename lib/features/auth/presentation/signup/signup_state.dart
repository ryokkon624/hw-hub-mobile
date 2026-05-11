class SignupSuccessResult {
  const SignupSuccessResult({
    required this.email,
    required this.requiresEmailVerify,
  });

  final String email;
  final bool requiresEmailVerify;
}

class SignupState {
  const SignupState({
    this.email = '',
    this.displayName = '',
    this.password = '',
    this.passwordConfirm = '',
    this.locale = 'ja',
    this.isLoading = false,
    this.errorMessage,
    this.successResult,
  });

  final String email;
  final String displayName;
  final String password;
  final String passwordConfirm;
  final String locale;
  final bool isLoading;
  final String? errorMessage;
  final SignupSuccessResult? successResult;

  bool get canSubmit =>
      email.trim().isNotEmpty &&
      displayName.trim().isNotEmpty &&
      password.length >= 8 &&
      password == passwordConfirm &&
      !isLoading;

  SignupState copyWith({
    String? email,
    String? displayName,
    String? password,
    String? passwordConfirm,
    String? locale,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? successResult = _sentinel,
  }) => SignupState(
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    password: password ?? this.password,
    passwordConfirm: passwordConfirm ?? this.passwordConfirm,
    locale: locale ?? this.locale,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
    successResult: successResult == _sentinel
        ? this.successResult
        : successResult as SignupSuccessResult?,
  );

  static const _sentinel = Object();
}
