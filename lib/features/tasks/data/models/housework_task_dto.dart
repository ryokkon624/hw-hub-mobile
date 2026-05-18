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

  HouseworkTaskDto copyWith({
    int? houseworkTaskId,
    int? householdId,
    int? houseworkId,
    String? houseworkName,
    Object? categoryCode = _sentinel,
    String? targetDate,
    Object? assigneeUserId = _sentinel,
    Object? assigneeNickname = _sentinel,
    String? status,
    Object? assignReasonType = _sentinel,
    Object? doneAt = _sentinel,
    Object? skippedReason = _sentinel,
  }) {
    return HouseworkTaskDto(
      houseworkTaskId: houseworkTaskId ?? this.houseworkTaskId,
      householdId: householdId ?? this.householdId,
      houseworkId: houseworkId ?? this.houseworkId,
      houseworkName: houseworkName ?? this.houseworkName,
      categoryCode: identical(categoryCode, _sentinel)
          ? this.categoryCode
          : categoryCode as String?,
      targetDate: targetDate ?? this.targetDate,
      assigneeUserId: identical(assigneeUserId, _sentinel)
          ? this.assigneeUserId
          : assigneeUserId as int?,
      assigneeNickname: identical(assigneeNickname, _sentinel)
          ? this.assigneeNickname
          : assigneeNickname as String?,
      status: status ?? this.status,
      assignReasonType: identical(assignReasonType, _sentinel)
          ? this.assignReasonType
          : assignReasonType as String?,
      doneAt: identical(doneAt, _sentinel) ? this.doneAt : doneAt as String?,
      skippedReason: identical(skippedReason, _sentinel)
          ? this.skippedReason
          : skippedReason as String?,
    );
  }
}

// nullable フィールドを null に上書きするための番兵オブジェクト
const _sentinel = Object();
