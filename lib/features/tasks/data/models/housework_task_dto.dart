class HouseworkTaskDto {
  const HouseworkTaskDto({
    required this.houseworkTaskId,
    required this.householdId,
    required this.houseworkId,
    required this.houseworkName,
    this.categoryCode,
    required this.targetDate,
    this.assigneeUserId,
    this.assigneeNickname,
    required this.status,
    this.assignReasonType,
    this.doneAt,
    this.skippedReason,
  });

  final int houseworkTaskId;
  final int householdId;
  final int houseworkId;
  final String houseworkName;
  final String? categoryCode;
  final String targetDate;
  final int? assigneeUserId;
  final String? assigneeNickname;
  final String status;
  final String? assignReasonType;
  final String? doneAt;
  final String? skippedReason;

  factory HouseworkTaskDto.fromJson(Map<String, dynamic> json) =>
      HouseworkTaskDto(
        houseworkTaskId: json['houseworkTaskId'] as int,
        householdId: json['householdId'] as int,
        houseworkId: json['houseworkId'] as int,
        houseworkName: json['houseworkName'] as String,
        categoryCode: json['categoryCode'] as String?,
        targetDate: json['targetDate'] as String,
        assigneeUserId: json['assigneeUserId'] as int?,
        assigneeNickname: json['assigneeNickname'] as String?,
        status: json['status'] as String,
        assignReasonType: json['assignReasonType'] as String?,
        doneAt: json['doneAt'] as String?,
        skippedReason: json['skippedReason'] as String?,
      );
}
