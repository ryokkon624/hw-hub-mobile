/// GET /api/users/me/profile のレスポンス DTO。
class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.email,
    required this.authProvider,
    required this.displayName,
    required this.locale,
    this.iconUrl,
  });

  final int userId;
  final String email;

  /// 認証プロバイダ（"LOCAL" / "GOOGLE"）
  final String authProvider;

  final String displayName;
  final String locale;
  final String? iconUrl;

  /// Google 認証のみのアカウントかどうか
  bool get isGoogleOnly => authProvider == 'GOOGLE';

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      authProvider: json['authProvider'] as String,
      displayName: json['displayName'] as String,
      locale: json['locale'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}
