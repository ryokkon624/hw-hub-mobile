/// GET /api/users/me/notification-settings のレスポンス DTO。
class NotificationSettingsDto {
  const NotificationSettingsDto({
    required this.notificationEnabled,
    required this.groupSettings,
  });

  final bool notificationEnabled;

  /// キー: グループコード（"100"=HOUSEHOLD, "200"=TASK_ASSIGNMENT 等）、値: 有効フラグ
  final Map<String, bool> groupSettings;

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) {
    final rawGroup = json['groupSettings'] as Map<String, dynamic>? ?? {};
    final group = rawGroup.map((k, v) => MapEntry(k, (v as bool?) ?? true));
    return NotificationSettingsDto(
      notificationEnabled: (json['notificationEnabled'] as bool?) ?? true,
      groupSettings: group,
    );
  }

  /// 更新リクエスト用 JSON に変換する。
  Map<String, dynamic> toUpdateJson() {
    return {
      'notificationEnabled': notificationEnabled,
      'groupSettings': groupSettings,
    };
  }
}
