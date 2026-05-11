import 'auth_user.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.emailVerificationRequired,
    this.accessToken,
    this.refreshToken,
    required this.user,
    this.verificationExpiresAt,
  });

  final bool emailVerificationRequired;
  final String? accessToken;
  final String? refreshToken;
  final AuthUser user;
  final String? verificationExpiresAt;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        emailVerificationRequired:
            json['emailVerificationRequired'] as bool,
        accessToken: json['accessToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        verificationExpiresAt: json['verificationExpiresAt'] as String?,
      );
}
