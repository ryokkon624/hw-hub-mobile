import 'auth_user.dart';

class LoginResponse {
  const LoginResponse({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
