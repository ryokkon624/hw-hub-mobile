class NotificationDto {
  const NotificationDto({
    required this.notificationId,
    required this.isRead,
    required this.occurredAt,
    required this.titleKey,
    required this.bodyKey,
    required this.params,
    required this.linkType,
    this.linkId,
    required this.aggregatedCount,
  });

  final int notificationId;
  final bool isRead;
  final String occurredAt;
  final String titleKey;
  final String bodyKey;
  final Map<String, dynamic> params;
  final String linkType;
  final int? linkId;
  final int aggregatedCount;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      notificationId: json['notificationId'] as int,
      isRead: json['isRead'] as bool,
      occurredAt: json['occurredAt'] as String,
      titleKey: json['titleKey'] as String,
      bodyKey: json['bodyKey'] as String,
      params: (json['params'] as Map<String, dynamic>?) ?? {},
      linkType: json['linkType'] as String,
      linkId: json['linkId'] as int?,
      aggregatedCount: json['aggregatedCount'] as int,
    );
  }
}
