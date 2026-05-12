// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'housework_task_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseworkTaskDto _$HouseworkTaskDtoFromJson(Map<String, dynamic> json) =>
    HouseworkTaskDto(
      houseworkTaskId: (json['houseworkTaskId'] as num).toInt(),
      householdId: (json['householdId'] as num).toInt(),
      houseworkId: (json['houseworkId'] as num).toInt(),
      houseworkName: json['houseworkName'] as String,
      categoryCode: json['categoryCode'] as String?,
      targetDate: json['targetDate'] as String,
      assigneeUserId: (json['assigneeUserId'] as num?)?.toInt(),
      assigneeNickname: json['assigneeNickname'] as String?,
      status: json['status'] as String,
      assignReasonType: json['assignReasonType'] as String?,
      doneAt: json['doneAt'] as String?,
      skippedReason: json['skippedReason'] as String?,
    );

Map<String, dynamic> _$HouseworkTaskDtoToJson(HouseworkTaskDto instance) =>
    <String, dynamic>{
      'houseworkTaskId': instance.houseworkTaskId,
      'householdId': instance.householdId,
      'houseworkId': instance.houseworkId,
      'houseworkName': instance.houseworkName,
      'categoryCode': instance.categoryCode,
      'targetDate': instance.targetDate,
      'assigneeUserId': instance.assigneeUserId,
      'assigneeNickname': instance.assigneeNickname,
      'status': instance.status,
      'assignReasonType': instance.assignReasonType,
      'doneAt': instance.doneAt,
      'skippedReason': instance.skippedReason,
    };
