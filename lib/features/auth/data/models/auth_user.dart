class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  final int userId;
  final String email;
  final String displayName;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId'] as int,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
  );
}
