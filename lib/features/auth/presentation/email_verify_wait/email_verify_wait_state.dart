class EmailVerifyWaitState {
  const EmailVerifyWaitState({
    this.isSending = false,
    this.cooldownSeconds = 0,
    this.errorMessage,
    this.resentSuccess = false,
  });

  final bool isSending;
  final int cooldownSeconds;
  final String? errorMessage;
  final bool resentSuccess;

  bool get canResend => !isSending && cooldownSeconds == 0;

  EmailVerifyWaitState copyWith({
    bool? isSending,
    int? cooldownSeconds,
    Object? errorMessage = _sentinel,
    bool? resentSuccess,
  }) => EmailVerifyWaitState(
    isSending: isSending ?? this.isSending,
    cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
    resentSuccess: resentSuccess ?? this.resentSuccess,
  );

  static const _sentinel = Object();
}
