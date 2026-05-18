class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    required this.displayName,
    this.iconUrl,
  });

  final int userId;
  final String email;
  final String displayName;
  final String? iconUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: json['userId'] as int,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    iconUrl: json['iconUrl'] as String?,
  );
}
