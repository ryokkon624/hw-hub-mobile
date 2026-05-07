sealed class AuthState {
  const AuthState();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
