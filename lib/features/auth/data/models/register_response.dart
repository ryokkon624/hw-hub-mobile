import 'auth_user.dart';

class RegisterResponse {
  const RegisterResponse({
    required this.emailVerificationRequired,
    this.token,
    required this.user,
    this.verificationExpiresAt,
  });

  final bool emailVerificationRequired;
  final String? token;
  final AuthUser user;
  final String? verificationExpiresAt;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        emailVerificationRequired:
            json['emailVerificationRequired'] as bool,
        token: json['token'] as String?,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        verificationExpiresAt: json['verificationExpiresAt'] as String?,
      );
}
