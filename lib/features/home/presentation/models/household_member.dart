/// プレゼンテーション層で使う世帯メンバーモデル
class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.displayName,
    this.iconUrl,
    this.nickname,
  });

  final int userId;
  final String displayName;
  final String? iconUrl;
  final String? nickname;
}
