class PasswordResetSentState {
  const PasswordResetSentState({
    this.isSending = false,
    this.errorMessage,
    this.resentSuccess = false,
  });

  final bool isSending;
  final String? errorMessage;
  final bool resentSuccess;

  PasswordResetSentState copyWith({
    bool? isSending,
    Object? errorMessage = _sentinel,
    bool? resentSuccess,
  }) =>
      PasswordResetSentState(
        isSending: isSending ?? this.isSending,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        resentSuccess: resentSuccess ?? this.resentSuccess,
      );

  static const _sentinel = Object();
}
