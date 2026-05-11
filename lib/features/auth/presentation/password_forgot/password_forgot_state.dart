class PasswordForgotState {
  const PasswordForgotState({
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
    this.sentEmail,
  });

  final String email;
  final bool isLoading;
  final String? errorMessage;
  final String? sentEmail;

  bool get canSubmit => email.trim().isNotEmpty && !isLoading;

  PasswordForgotState copyWith({
    String? email,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    Object? sentEmail = _sentinel,
  }) => PasswordForgotState(
    email: email ?? this.email,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
    sentEmail: sentEmail == _sentinel ? this.sentEmail : sentEmail as String?,
  );

  static const _sentinel = Object();
}
